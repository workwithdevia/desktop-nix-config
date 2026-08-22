{pkgs, ...}: {
  programs.neovim = {
    enable = true;

    # Convierte a Neovim en el editor por defecto del sistema (git, visudo, etc.)
    defaultEditor = true;

    # Crea alias automáticos para no perder la costumbre
    viAlias = true;
    vimAlias = true;
  };

  # 1. Inyección de configuración
  # Esto le dice a Nix que tome la carpeta 'config' que está junto a este archivo
  # y la enlace de forma segura en ~/.config/nvim/
  xdg.configFile."nvim" = {
    source = ./config;
    recursive = true;
  };

  # 2. Dependencias del Ecosistema
  # Neovim moderno (LSP, Treesitter, Telescope) requiere herramientas externas
  # instaladas a nivel del sistema para funcionar correctamente.
  home.packages = with pkgs; [
    gcc # Compilador de C (estrictamente necesario para nvim-treesitter)
    ripgrep # Buscador de texto ultra rápido (requerido por Telescope)
    fd # Alternativa a 'find' (requerido por Telescope)
    wl-clipboard # Soporte para copiar/pegar al portapapeles en entornos Wayland (como Sway)

    # Servidores LSP básicos (puedes añadir los que uses para programar)
    lua-language-server
    nil # LSP para el lenguaje Nix
  ];
}
