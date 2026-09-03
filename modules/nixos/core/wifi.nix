{ config, pkgs, ... }: {
  # Habilitar NetworkManager para la gestión de red (Wi-Fi y Ethernet)
  networking.networkmanager.enable = true;

  # Asegurar soporte de firmware para tarjetas inalámbricas comunes (Intel, Realtek, etc.)
  hardware.enableRedistributableFirmware = true;
}