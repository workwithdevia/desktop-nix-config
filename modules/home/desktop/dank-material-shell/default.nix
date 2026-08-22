{pkgs, ...}: {
  programs.dank-material-shell = {
    enable = true;

    systemd = {
      enable = true;
      restartIfChanged = true;
    };

    plugins = {
      dockerManager.enable = true;
      notionManager = {
        enable = true;
        src = pkgs.fetchFromGitLab {
          owner = "workwithdevia-group";
          repo = "desktop/DmsNotionManager";
          rev = "v0.1.3";
          hash = "sha256-lkuHieUOo28KGW5iRg5WinJyrV/cqbkMi0CQaGUTXwg=";
        };
      };
    };
  };

  xdg.configFile."DankMaterialShell" = {
    source = ./config;
    recursive = true;
  };
}
