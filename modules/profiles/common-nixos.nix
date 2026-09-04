# Perfil: común — NixOS compartido entre todos los hosts
{isLaptop, ...}: {
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
}
