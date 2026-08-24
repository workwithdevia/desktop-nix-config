{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.rclone-google-drive;

  remoteTarget = dirCfg: let
    prefix = lib.optionalString (cfg.remoteRoot != "") "${cfg.remoteRoot}/";
  in "${cfg.remoteName}:${prefix}${dirCfg.remotePath}";

  syncCommands = lib.concatMapStringsSep "\n\n" (
    name: let
      dirCfg = cfg.directories.${name};
      args = lib.escapeShellArgs cfg.extraArgs;

      # La condición se resuelve en tiempo de evaluación de Nix
      rcloneAction =
        if cfg.mode == "bisync"
        then ''
          if ! ${pkgs.rclone}/bin/rclone bisync \
            ${lib.escapeShellArg dirCfg.localPath} \
            ${lib.escapeShellArg (remoteTarget dirCfg)} \
            ${args}; then
            echo "bisync falló. Ejecutando --resync automático..."
            ${pkgs.rclone}/bin/rclone bisync \
              ${lib.escapeShellArg dirCfg.localPath} \
              ${lib.escapeShellArg (remoteTarget dirCfg)} \
              ${args} --resync
          fi
        ''
        else ''
          ${pkgs.rclone}/bin/rclone sync \
            ${lib.escapeShellArg dirCfg.localPath} \
            ${lib.escapeShellArg (remoteTarget dirCfg)} \
            ${args}
        '';
    in ''
      if [ -d ${lib.escapeShellArg dirCfg.localPath} ]; then
        echo "Syncing ${dirCfg.localPath} -> ${remoteTarget dirCfg}"
        ${rcloneAction}
      else
        echo "Skipping missing directory: ${dirCfg.localPath}"
      fi
    ''
  ) (builtins.attrNames cfg.directories);

  syncScript = pkgs.writeShellApplication {
    name = "rclone-google-drive-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux
      pkgs.rclone
    ];
    text = ''
      set -euo pipefail

      export RCLONE_CONFIG=${lib.escapeShellArg cfg.configFile}

      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      mkdir -p "$runtime_dir"
      lock_file="$runtime_dir/rclone-google-drive.lock"
      exec 9>"$lock_file"

      if ! flock -n 9; then
        echo "rclone-google-drive-sync: another sync is already running"
        exit 0
      fi

      ${syncCommands}
    '';
  };
in {
  options.services.rclone-google-drive = {
    enable = lib.mkEnableOption "periodic Google Drive sync with rclone";

    mode = lib.mkOption {
      type = lib.types.enum [
        "sync"
        "bisync"
      ];
      default = "sync";
      description = ''
        rclone operation mode. `sync` is one-way local -> Google Drive.
        `bisync` is two-way.
      '';
    };

    remoteName = lib.mkOption {
      type = lib.types.str;
      default = "gdrive";
      description = "Name of the configured rclone remote.";
      example = "google";
    };

    remoteRoot = lib.mkOption {
      type = lib.types.str;
      default = "Backups";
      description = "Base folder inside the Google Drive remote.";
      example = "MySync";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
      description = ''
        Path to the rclone config file containing the Google Drive OAuth token.
      '';
      example = "${config.home.homeDirectory}/.config/rclone/rclone.conf";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "15m";
      description = "Timer interval for periodic syncs.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--fast-list"
        "--drive-skip-gdocs"
        "--verbose"
      ];
      description = "Additional CLI arguments passed to each rclone invocation.";
    };

    directories = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          {name, ...}: {
            options = {
              localPath = lib.mkOption {
                type = lib.types.str;
                default = "${config.home.homeDirectory}/${name}";
                description = "Local directory to sync.";
              };

              remotePath = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Directory name under the configured Google Drive remote root.";
              };
            };
          }
        )
      );
      default = {
        Documents = {};
        Music = {};
        Images = {};
      };
      description = "Directories to sync, keyed by a friendly name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.configFile != "";
        message = "services.rclone-google-drive.configFile must point to a valid rclone.conf path.";
      }
      {
        assertion = cfg.directories != {};
        message = "services.rclone-google-drive.directories must contain at least one entry.";
      }
    ];

    home.packages = [pkgs.rclone];

    systemd.user.services.rclone-google-drive = {
      Unit = {
        Description = "Synchronize selected folders with Google Drive via rclone";
        Documentation = ["man:rclone(1)"];
        After = ["network-online.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${syncScript}/bin/rclone-google-drive-sync";
      };
    };

    systemd.user.timers.rclone-google-drive = {
      Unit.Description = "Run rclone Google Drive sync periodically";

      Timer = {
        OnBootSec = "5m";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
        Unit = "rclone-google-drive.service";
      };

      Install.WantedBy = ["timers.target" "default.target"];
    };
  };
}
