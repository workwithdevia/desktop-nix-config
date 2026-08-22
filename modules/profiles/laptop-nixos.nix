# Perfil: laptop-nixos — NixOS extras para pc-portatil (wifi, tlp, bluetooth + GitLab Runner)
{config, ...}: {
  imports = [
    ../nixos/core/wifi.nix
    ../nixos/services/gitlab-runner.nix
  ];

  # Gestión de energía (solo portátiles)
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };

  # Bluetooth para periféricos móviles
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # WiFi: las redes se cargan desde sops-nix secrets (wifi/networks)
  networking.wireless = {
    enable = true;
    secretsFile = config.sops.secrets."wifi/networks".path;
  };

  # GitLab Runner para CI/CD local (tag: pc-portatil)
  services.gitlab-runner-local = {
    enable = true;
    tags = ["pc-portatil" "nixos" "x86_64-linux"];
  };
}
