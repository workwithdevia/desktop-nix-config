{
  pkgs,
  inputs,
  ...
}: {
  # Firewall global habilitado
  networking.firewall.enable = true;

  networking.nftables.enable = true;

  # Polkit esencial para Wayland
  security.polkit.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  powerManagement.cpuFreqGovernor = "performance";

  # Enable fast memory compression in RAM
  zramSwap.enable = true;

  # Tweak kernel parameters for better memory management
  boot.kernel.sysctl = {
    # Keep software in physical RAM longer before swapping
    "vm.swappiness" = 10;

    # Improve filesystem cache management
    "vm.vfs_cache_pressure" = 50;
  };

  boot.kernelPackages = inputs.nix-cachyos-kernel.legacyPackages.${pkgs.system}.linuxPackages-cachyos-bore-lto-x86_64-v3;
}
