{pkgs, ...}: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Fuentes de código e íconos existentes
    fira-code
    font-awesome
    nerd-fonts.jetbrains-mono

    # Estándares de oficina (Reemplazos métricos para LibreOffice)
    liberation_ttf # Reemplazo con exactitud métrica de Arial, Times New Roman y Courier New
    dejavu_fonts # Cobertura completa de caracteres y símbolos clásicos en Linux

    # Cobertura global de Unicode y Emojis
    noto-fonts # Fuentes universales de Google para evitar caracteres rotos
    noto-fonts-cjk-sans # Compatibilidad con caracteres asiáticos (Chino, Japonés, Coreano)
    noto-fonts-color-emoji # Emojis en color para todo el sistema
    google-fonts

    # Tipografías UI populares en web y escritorio
    inter # Tipografía estándar de interfaces modernas
    roboto # Tipografía de Android / Material Design
    cantarell-fonts # Tipografía predeterminada del escritorio GNOME

    # Fuentes propietarios oficiales de Microsoft
    corefonts # Arial, Times New Roman, Georgia, Verdana, Trebuchet MS, etc.
  ];
}
