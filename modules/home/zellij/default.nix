{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
  };

  # Si tienes un archivo config.kdl o temas personalizados, los guardas
  # en la carpeta 'modules/home/zellij/config/' y Nix los enlazará automáticamente.
  xdg.configFile."zellij" = {
    source = ./config;
    recursive = true;
  };
}
