{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = (pkgs.vscode.override {isInsiders = true;}).overrideAttrs (oldAttrs: rec {
      src = builtins.fetchTarball {
        url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
        # Colocamos un placeholder temporal para que Nix falle y nos dé el hash correcto en consola
        sha256 = "1ja2pvzf43pc0l16f9yc8602ba1sajq4k6rb3y4l05l18237m2zf";
      };
      version = "latest";

      buildInputs =
        oldAttrs.buildInputs
        ++ [
          pkgs.krb5
          pkgs.libsoup_3
          pkgs.webkitgtk_4_1
        ];
    });
  };
}
