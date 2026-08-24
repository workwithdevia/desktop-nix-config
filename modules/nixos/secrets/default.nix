# Perfil: secrets — Gestión de secretos cifrados con sops-nix (AGE encryption)
# Los secretos se definen en hosts/<hostname>/secrets.yaml y se descifran automáticamente
# al hacer nixos-rebuild. Se exponen como archivos en rutas fijas.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  # El servicio sops-nix a nivel de Home Manager corre como `workwithdevia`,
  # que no puede leer la host key root:root 0600. La hacemos legible por el
  # grupo `users` (grupo principal del usuario ya en sesión, sin re-login).
  # El activation script corrige los permisos en cada `nixos-rebuild` con
  # efecto inmediato; tmpfiles la re-afirma en cada boot.
  system.activationScripts.hostKeyReadable = {
    deps = ["users"];
    text = ''
      chgrp users /etc/ssh/ssh_host_ed25519_key
      chmod 0640 /etc/ssh/ssh_host_ed25519_key
    '';
  };

  systemd.tmpfiles.rules = [
    "z /etc/ssh/ssh_host_ed25519_key 0640 root users"
  ];

  sops = {
    defaultSopsFile = ../../../hosts/${config.networking.hostName}/secrets.yaml;
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops/age-key";
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
    secrets = {
      # rclone → archivo de configuración que lee el servicio rclone-google-drive
      "rclone/config" = {
        path = "/home/workwithdevia/.config/rclone/rclone.conf";
        owner = "workwithdevia";
        group = "users";
        mode = "0600";
      };
      # GitLab Runner → registration token para CI/CD local
      "gitlab/runner_token" = {
        owner = "gitlab-runner";
        group = "gitlab-runner";
        mode = "0400";
      };
    };
  };
}
