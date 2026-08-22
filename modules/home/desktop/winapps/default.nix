{pkgs, ...}: {
  home.packages = with pkgs; [
    # Asegúrate de tener freerdp y libvirt si winapps los requiere localmente
    freerdp
  ];

  xdg.configFile."winapps" = {
    source = ./config;
    recursive = true;
  };
}
