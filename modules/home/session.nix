{pkgs, ...}: {
  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "wezterm";
    DEFAULT_TERMINAL = "wezterm";
    XDG_DATA_DIRS = "$GSETTINGS_SCHEMAS_PATH";
    PKG_CONFIG_PATH = "${pkgs.glib.dev}/lib/pkgconfig:${pkgs.gdk-pixbuf.dev}/lib/pkgconfig:${pkgs.gtk3.dev}/lib/pkgconfig:$PKG_CONFIG_PATH";
  };
}
