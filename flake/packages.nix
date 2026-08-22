{pkgs}: {
  # ==========================================================
  # CHECK HOST
  # ==========================================================

  check-host = pkgs.writeShellApplication {
    name = "check-host";

    runtimeInputs = [
      pkgs.nix
    ];

    text = ''
      host="''${1:-pc-wwd}"

      exec nix \
        --extra-experimental-features "nix-command flakes" \
        build \
        --print-out-paths \
        ".#nixosConfigurations.''${host}.config.system.build.toplevel" \
        --no-link
    '';
  };
}
