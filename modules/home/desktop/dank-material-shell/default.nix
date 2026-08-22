{pkgs, ...}: {
  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    plugins = {
      dockerManager.enable = true;
    };
  };

  xdg.configFile."DankMaterialShell" = {
    source = ./config;
    recursive = true;
  };
}
