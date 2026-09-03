# Perfil: security-cis — Hardening CIS Benchmark Nivel 1
# Activable por flags granulares desde los perfiles desktop.nix / laptop.nix
{
  config,
  lib,
  isLaptop,
  ...
}: let
  cfg = config.security.hardening;
in {
  options.security.hardening = {
    enableAppArmor = lib.mkEnableOption "AppArmor LSM";
    enableAuditd = lib.mkEnableOption "auditd logging";
    enableFail2ban = lib.mkEnableOption "fail2ban SSH protection";
    enableKernelHardening = lib.mkEnableOption "kernel hardening params";
    enableFirewallStrict = lib.mkEnableOption "strict firewall rules";
    enableOpenSSH = lib.mkEnableOption "OpenSSH secure server";
  };

  config = {
    security.apparmor.enable = cfg.enableAppArmor;

    security.auditd.enable = cfg.enableAuditd;

    services.fail2ban = lib.mkIf cfg.enableFail2ban {
      enable = true;
      bantime = "24h";
      maxretry = 3;
    };

    boot.kernelParams = lib.mkIf cfg.enableKernelHardening (
      [
        "mitigations=auto"
        "slab_nomerge"
        "page_poison=1"
        "init_on_alloc=1"
        "init_on_free=1"
        "random.trust_cpu=off"
      ]
      ++ lib.optionals (!isLaptop) [
        "lockdown=confidentiality"
      ]
    );

    networking.firewall = lib.mkIf cfg.enableFirewallStrict {
      enable = true;
      allowedTCPPorts = [22];
      allowedUDPPorts = [];
      allowPing = false;
      logReversePathDrops = true;
    };
  };
}
