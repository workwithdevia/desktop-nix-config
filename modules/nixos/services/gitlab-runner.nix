# Servicio: GitLab Runner — CI/CD local en pc-wwd
# Shell executor usando systemd directamente
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.gitlab-runner-local;
in {
  options.services.gitlab-runner-local = {
    enable = lib.mkEnableOption "GitLab Runner local CI/CD (shell executor)";

    gitlabUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://gitlab.com";
    };

    tags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "pc-wwd"
        "nixos"
        "x86_64-linux"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # ============================================================
    # PACKAGES
    # ============================================================

    environment.systemPackages = [
      pkgs.gitlab-runner
    ];

    # ============================================================
    # GITLAB RUNNER USER
    # ============================================================

    users.groups.gitlab-runner = {};

    users.users.gitlab-runner = {
      isSystemUser = true;
      group = "gitlab-runner";

      # Necesario para los comandos permitidos mediante sudo.
      extraGroups = ["wheel"];
    };

    # ============================================================
    # RUNNER REGISTRATION
    # ============================================================

    systemd.services.gitlab-runner-register = {
      description = "Register GitLab Runner (oneshot)";

      restartIfChanged = false;

      after = [
        "network-online.target"
      ];

      wants = [
        "network-online.target"
      ];

      wantedBy = [
        "multi-user.target"
      ];

      path = with pkgs; [
        bash
        coreutils
        git
        nix
        gnused
        gitlab-runner
      ];

      serviceConfig = {
        Type = "oneshot";

        User = "root";
        Group = "root";

        Environment = "HOME=/var/lib/gitlab-runner";

        StateDirectory = "gitlab-runner";

        ExecStart = pkgs.writeShellScript "gitlab-runner-register-once" ''
          set -euo pipefail

          CONFIG="/etc/gitlab-runner/config.toml"
          TOKEN_FILE="${config.sops.secrets."gitlab/runner_token".path}"

          echo "Checking GitLab Runner registration..."

          # ----------------------------------------------------------
          # REGISTER RUNNER IF NEEDED
          # ----------------------------------------------------------

          if [ -f "$CONFIG" ] && grep -qE '^[[:space:]]*token[[:space:]]*=' "$CONFIG"; then
            echo "GitLab Runner already registered."
          else
            echo "GitLab Runner is not registered."
            echo "Registering runner on ${cfg.gitlabUrl}..."

            TOKEN="$(cat "$TOKEN_FILE")"

            ${pkgs.gitlab-runner}/bin/gitlab-runner register \
              --non-interactive \
              --url "${cfg.gitlabUrl}" \
              --registration-token "$TOKEN" \
              --executor shell \
              --shell bash \
              --tag-list "${lib.concatStringsSep "," cfg.tags}" \
              --description "pc-wwd-nixos-runner"

            echo "Runner registered successfully."
          fi

          # ----------------------------------------------------------
          # CONFIGURE RUNNER
          # ----------------------------------------------------------

          echo "Configuring GitLab Runner..."

          # concurrent:
          # Maximum number of jobs that this machine executes
          # simultaneously.
          #
          # We intentionally keep this at 1 because pc-wwd is also
          # the machine being deployed.
          ${pkgs.gnused}/bin/sed -i \
            -E 's/^concurrent[[:space:]]*=.*/concurrent = 1/' \
            "$CONFIG"

          # Add concurrent if it does not exist.
          if ! grep -qE '^concurrent[[:space:]]*=' "$CONFIG"; then
            sed -i '1i concurrent = 1' "$CONFIG"
          fi

          # check_interval = 0 enables the runner's normal polling
          # behaviour.
          if grep -qE '^check_interval[[:space:]]*=' "$CONFIG"; then
            sed -i \
              -E 's/^check_interval[[:space:]]*=.*/check_interval = 0/' \
              "$CONFIG"
          else
            sed -i '2i check_interval = 0' "$CONFIG"
          fi

          # ----------------------------------------------------------
          # REQUEST CONCURRENCY
          # ----------------------------------------------------------
          #
          # This is different from "concurrent".
          #
          # concurrent = 1
          #   -> only one job executes at a time.
          #
          # request_concurrency = 2
          #   -> the runner can maintain two job requests to GitLab.
          #
          # This helps prevent the runner from remaining idle while
          # a new job is waiting in GitLab.
          #
          if grep -qE '^[[:space:]]*request_concurrency[[:space:]]*=' "$CONFIG"; then
            sed -i \
              -E 's/^[[:space:]]*request_concurrency[[:space:]]*=.*/request_concurrency = 2/' \
              "$CONFIG"
          else
            # Insert it inside the first [[runners]] block.
            ${pkgs.gnused}/bin/sed -i \
              '/^\[\[runners\]\]/a request_concurrency = 2' \
              "$CONFIG"
          fi

          echo "GitLab Runner configuration:"
          echo "----------------------------------------"
          grep -E \
            '^(concurrent|check_interval|request_concurrency)[[:space:]]*=' \
            "$CONFIG" || true
          echo "----------------------------------------"

          echo "GitLab Runner registration/configuration complete."
        '';

        RemainAfterExit = true;
      };
    };

    # ============================================================
    # GITLAB RUNNER SERVICE
    # ============================================================

    systemd.services.gitlab-runner = {
      description = "GitLab Runner (system-mode shell executor)";

      # IMPORTANT:
      #
      # Do not automatically restart the runner when the NixOS
      # configuration changes.
      #
      # This prevents nixos-rebuild switch executed by CI from
      # restarting the runner while the runner itself is executing
      # the deployment.
      restartIfChanged = false;

      after = [
        "gitlab-runner-register.service"
        "network-online.target"
      ];

      wants = [
        "network-online.target"
      ];

      requires = [
        "gitlab-runner-register.service"
      ];

      wantedBy = [
        "multi-user.target"
      ];

      path = with pkgs; [
        bash
        git
        nix
        coreutils
        gitMinimal
        config.system.build.nixos-rebuild
      ];

      serviceConfig = {
        Type = "simple";

        User = "root";
        Group = "root";

        Environment = "HOME=/var/lib/gitlab-runner";

        WorkingDirectory = "/var/lib/gitlab-runner";

        StateDirectory = "gitlab-runner";

        ExecStart =
          "${pkgs.gitlab-runner}/bin/gitlab-runner run"
          + " --config /etc/gitlab-runner/config.toml"
          + " --working-directory /var/lib/gitlab-runner";

        Restart = "always";

        RestartSec = 10;

        TimeoutStopSec = "30s";
      };
    };

    # ============================================================
    # SUDO PERMISSIONS
    # ============================================================

    security.sudo.extraRules = [
      {
        users = ["gitlab-runner"];

        commands = [
          {
            command = "/run/current-system/sw/bin/nix";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }

          {
            command = "${pkgs.nix}/bin/nix";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }

          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }

          {
            command = "${config.system.build.nixos-rebuild}/bin/nixos-rebuild";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];
  };
}
