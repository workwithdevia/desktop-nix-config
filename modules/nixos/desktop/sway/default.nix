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

  services.displayManager.dms-greeter = {
    enable = true;
    configHome = "/home/${username}";
    compositor.name = "sway";
  };
}
