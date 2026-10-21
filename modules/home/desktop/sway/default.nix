{
  xdg.configFile."sway" = {
    source = ./config;
    recursive = true;
  };

  # Make all files inside ~/.config/sway/scripts executable
  xdg.configFile."sway/scripts" = {
    source = ./config/scripts;
    recursive = true;
    executable = true;
  };
}
