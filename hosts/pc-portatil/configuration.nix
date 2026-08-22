{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/common-nixos.nix
    ../../modules/profiles/laptop-nixos.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "pc-portatil";
  system.stateVersion = "26.11";
}
