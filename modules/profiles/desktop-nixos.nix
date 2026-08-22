# Perfil: desktop-nixos — NixOS extras para pc-wwd (virtualización extendida + GitLab Runner)
{...}: {
  imports = [
    /*
      ../nixos/virtualisation/libvirt.nix
    ../nixos/virtualisation/waydroid.nix
    ../nixos/virtualisation/android.nix
    */
    ../nixos/services/gitlab-runner.nix
  ];

  services.gitlab-runner-local = {
    enable = true;
  };
}
