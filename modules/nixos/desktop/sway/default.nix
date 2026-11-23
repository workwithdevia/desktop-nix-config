{
  pkgs,
  username,
  ...
}: {
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
  };

  environment.pathsToLink = [
    "/share/applications"
    "/share/xdg-desktop-portal"
  ];

  services.displayManager.dux-greeter = {
    enable = true;
    configHome = "/home/${username}";
    compositor.name = "sway";
  };

  # Garantizar los permisos del caché privado de Dux Greeter.
  systemd.tmpfiles.settings."10-dms-greeter-cache" = {
    "/var/lib/dms-greeter/.cache".d = {
      user = "dms-greeter";
      group = "dms-greeter";
      mode = "0700";
    };
  };
}
