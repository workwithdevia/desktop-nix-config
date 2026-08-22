{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/common-nixos.nix
    ../../modules/profiles/desktop-nixos.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "pc-wwd";
  system.stateVersion = "26.11";
}
