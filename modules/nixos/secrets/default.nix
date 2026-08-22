# Perfil: secrets — Gestión de secretos cifrados con sops-nix (AGE encryption)
# Los secretos se definen en secrets/<hostname>.yaml y se descifran automáticamente
# al hacer nixos-rebuild. Se exponen como archivos en rutas fijas.
{
  config,
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [inputs.sops-nix.nixosModules.sops];

  sops = {
    defaultSopsFile = ../../../secrets/${config.networking.hostName}.yaml;
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
      # WiFi → redes inalámbricas para wpa_supplicant (pc-portatil)
      "wifi/networks" = {
        owner = "root";
        group = "root";
        mode = "0600";
      };
      # GitLab Runner → registration token para CI/CD local (pc-wwd)
      "gitlab/runner_token" = {
        owner = "gitlab-runner";
        group = "gitlab-runner";
        mode = "0400";
      };
    };
  };
}
