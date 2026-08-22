inputs: let
  # ==========================================================
  # SYSTEM
  # ==========================================================
  system = "x86_64-linux";
  username = "workwithdevia";

  inherit (inputs.nixpkgs) lib;

  # ==========================================================
  # PACKAGE SET
  # ==========================================================

  pkgs = import inputs.nixpkgs {
    inherit system;

    overlays = [
      inputs.nur.overlays.default
    ];

    config.allowUnfree = true;
  };

  # ==========================================================
  # NIXOS HOST FACTORY
  # ==========================================================

  mkHost = hostname: isLaptop:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit
          inputs
          username
          system
          hostname
          isLaptop
          ;
      };

      modules = [
        # ------------------------------------------------------
        # Host configuration
        # ------------------------------------------------------

        ../hosts/${hostname}/configuration.nix

        # ------------------------------------------------------
        # Nixpkgs configuration
        # ------------------------------------------------------

        {
          nixpkgs = {
            overlays = [
              inputs.nur.overlays.default
            ];

            config.allowUnfree = true;
          };
        }

        # ------------------------------------------------------
        # WinApps
        # ------------------------------------------------------

        {
          environment.systemPackages = [
            inputs.winapps.packages.${system}.winapps
            inputs.winapps.packages.${system}.winapps-launcher
          ];
        }

        # ------------------------------------------------------
        # Home Manager
        # ------------------------------------------------------

        inputs.home-manager.nixosModules.home-manager

        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            backupFileExtension = "backup";

            extraSpecialArgs = {
              inherit
                inputs
                username
                system
                hostname
                isLaptop
                ;
            };

            sharedModules = [
              inputs.dms.homeModules.dank-material-shell
              inputs.dms-plugin-registry.homeModules.default
              inputs.danksearch.homeModules.dsearch
            ];

            users.${username}.imports = [
              ../hosts/${hostname}/home.nix
            ];
          };
        }
      ];
    };

  # ==========================================================
  # HOSTS
  # ==========================================================

  nixosConfigurations = {
    pc-wwd = mkHost "pc-wwd" false;
    pc-portatil = mkHost "pc-portatil" true;
  };
in {
  # ==========================================================
  # NIXOS CONFIGURATIONS
  # ==========================================================

  inherit nixosConfigurations;

  # ==========================================================
  # FORMATTER
  # ==========================================================

  formatter.${system} = pkgs.alejandra;

  # ==========================================================
  # CUSTOM PACKAGES
  # ==========================================================

  packages.${system} = import ./packages.nix {
    inherit pkgs;
  };

  # ==========================================================
  # FLAKE CHECKS
  # ==========================================================

  checks.${system} =
    builtins.mapAttrs (
      _: config:
        config.config.system.build.toplevel
    )
    nixosConfigurations;

  # ==========================================================
  # DEVELOPMENT ENVIRONMENT
  # ==========================================================

  devShells.${system}.default = import ./devshell.nix {
    inherit pkgs;
  };
}
