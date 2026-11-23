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
      inputs.nix-cachyos-kernel.overlays.pinned
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
              inputs.nix-cachyos-kernel.overlays.pinned
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
              inputs.sops-nix.homeManagerModules.sops
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

  homeUser = config: role: let
    roleConfig =
      if role == "Common"
      then config.config
      else config.config.specialisation.${role}.configuration;
  in
    roleConfig.home-manager.users.${username};

  packageNames = packages: map lib.getName packages;

  checkRoleBoundaries = hostName: host: let
    commonConfig = host.config;
    developmentConfig = host.config.specialisation.Development.configuration;
    designConfig = host.config.specialisation.Design.configuration;
    securityAuditConfig = host.config.specialisation.SecurityAudit.configuration;
    commonHomePackages = packageNames (homeUser host "Common").home.packages;
    developmentHomePackages = packageNames (homeUser host "Development").home.packages;
    designHomePackages = packageNames (homeUser host "Design").home.packages;
    securityAuditHomePackages = packageNames (homeUser host "SecurityAudit").home.packages;
    commonSystemPackages = packageNames commonConfig.environment.systemPackages;
    developmentSystemPackages = packageNames developmentConfig.environment.systemPackages;
    designSystemPackages = packageNames designConfig.environment.systemPackages;
    developmentOnlyPackages = [
      "cargo"
      "clippy"
      "python3"
      "ruff"
      "rust-analyzer"
      "rustc"
      "rustfmt"
      "sqlite"
      "tinymist"
      "typst"
      "uv"
    ];
    designOnlyPackages = ["freecad" "gimp" "inkscape" "librecad"];
    securityAuditOnlyPackages = ["caido-desktop" "checksec" "clamav" "exploitdb" "ffuf" "gitleaks" "gobuster" "grype" "hashcat" "hydra" "john" "kics" "lynis" "metasploit-framework" "netcat-openbsd" "nikto" "nuclei" "osv-scanner" "scapy" "seclists" "semgrep" "sqlmap" "syft" "tcpdump" "testssl.sh" "trufflehog" "trivy" "wireshark-cli" "yara"];
    missingPackages = available: required:
      builtins.filter (package: !(builtins.elem package available)) required;
    forbidPackages = available: forbidden:
      builtins.all (package: !(builtins.elem package available)) forbidden;
  in
    assert builtins.hasAttr "Development" commonConfig.specialisation;
    assert builtins.hasAttr "Design" commonConfig.specialisation;
    assert builtins.hasAttr "SecurityAudit" commonConfig.specialisation;
    assert lib.hasSuffix "-Common" commonConfig.system.nixos.label;
    assert lib.hasSuffix "-Development" developmentConfig.system.nixos.label;
    assert lib.hasSuffix "-Design" designConfig.system.nixos.label;
    assert lib.hasSuffix "-SecurityAudit" securityAuditConfig.system.nixos.label;
    assert (homeUser host "Common").home.activationPackage.drvPath != null;
    assert (homeUser host "Development").home.activationPackage.drvPath != null;
    assert (homeUser host "Design").home.activationPackage.drvPath != null;
    assert (homeUser host "SecurityAudit").home.activationPackage.drvPath != null;
    assert missingPackages developmentHomePackages developmentOnlyPackages
    == []
    || throw "${hostName} Development is missing: ${builtins.concatStringsSep ", " (missingPackages developmentHomePackages developmentOnlyPackages)}";
    assert missingPackages designHomePackages designOnlyPackages
    == []
    || throw "${hostName} Design is missing: ${builtins.concatStringsSep ", " (missingPackages designHomePackages designOnlyPackages)}";
    assert missingPackages securityAuditHomePackages securityAuditOnlyPackages
    == []
    || throw "${hostName} SecurityAudit is missing: ${builtins.concatStringsSep ", " (missingPackages securityAuditHomePackages securityAuditOnlyPackages)}";
    assert forbidPackages commonHomePackages (developmentOnlyPackages ++ designOnlyPackages);
    assert forbidPackages commonHomePackages securityAuditOnlyPackages;
    assert forbidPackages developmentHomePackages designOnlyPackages;
    assert forbidPackages designHomePackages developmentOnlyPackages;
    assert forbidPackages securityAuditHomePackages (developmentOnlyPackages ++ designOnlyPackages);
    assert lib.sort builtins.lessThan commonSystemPackages == lib.sort builtins.lessThan developmentSystemPackages;
    assert lib.sort builtins.lessThan commonSystemPackages == lib.sort builtins.lessThan designSystemPackages;
    assert lib.sort builtins.lessThan commonSystemPackages == lib.sort builtins.lessThan (packageNames securityAuditConfig.environment.systemPackages); true;

  roleBoundaryCheck = assert builtins.all (hostName: checkRoleBoundaries hostName nixosConfigurations.${hostName}) ["pc-wwd" "pc-portatil"];
    pkgs.runCommand "work-mode-role-boundaries" {} "touch $out";
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
    nixosConfigurations
    // {
      role-boundaries = roleBoundaryCheck;
    };

  # ==========================================================
  # DEVELOPMENT ENVIRONMENT
  # ==========================================================

  devShells.${system}.default = import ./devshell.nix {
    inherit pkgs;
  };
}
