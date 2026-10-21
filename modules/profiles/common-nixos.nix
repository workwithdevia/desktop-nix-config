# Perfil: común — NixOS compartido entre todos los hosts
{
  config,
  isLaptop,
  lib,
  username,
  ...
}: {
  imports = [
    ../nixos
    ../nixos/desktop
    ../nixos/virtualisation/podman.nix
    ../nixos/secrets
    ../nixos/core/security-cis.nix
    ../nixos/core/luks-tpm.nix
    ../nixos/core/wifi.nix
  ];

  # Hardening base para todos los hosts
  security.hardening = {
    enableAppArmor = true;
    enableKernelHardening = true;
    enableFirewallStrict = true;
    # Solo auditd en escritorios (menos overhead de batería en laptop)
    enableAuditd = !isLaptop;
    enableOpenSSH = true;
    enableFail2ban = true;
  };

  system.nixos.label = "NixOS-${config.system.nixos.version}-Common";

  specialisation = {
    Development.configuration = {
      system.nixos.label = lib.mkForce "NixOS-${config.system.nixos.version}-Development";
      home-manager.users.${username}.imports = [
        ../home/packages/dev/compilers.nix
        ../home/packages/dev/lsp.nix
        ../home/packages/apps/develop.nix
      ];
    };

    Design.configuration = {
      system.nixos.label = lib.mkForce "NixOS-${config.system.nixos.version}-Design";
      home-manager.users.${username}.imports = [
        ../home/packages/apps/graphics.nix
      ];
    };
  };
}
