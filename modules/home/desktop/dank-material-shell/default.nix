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

  home.file = {
    # Archivos de configuración principal de DMS
    ".config/DankMaterialShell/session.json".source = ./config/session.json;
    ".config/DankMaterialShell/settings.json".source = ./config/settings.json;

    # Cheatsheets individuales
    ".config/DankMaterialShell/cheatsheets/lazygit.json".source = ./config/cheatsheets/lazygit.json;
    ".config/DankMaterialShell/cheatsheets/nvim.json".source = ./config/cheatsheets/nvim.json;
    ".config/DankMaterialShell/cheatsheets/sway.json".source = ./config/cheatsheets/sway.json;
    ".config/DankMaterialShell/cheatsheets/wezterm.json".source = ./config/cheatsheets/wezterm.json;
    ".config/DankMaterialShell/cheatsheets/chrome.json".source = ./config/cheatsheets/chrome.json;
  };
}
