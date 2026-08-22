{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = (pkgs.vscode.override {isInsiders = true;}).overrideAttrs (oldAttrs: rec {
      src = builtins.fetchTarball {
        url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
        # Colocamos un placeholder temporal para que Nix falle y nos dé el hash correcto en consola
        sha256 = "0arb4ncx6pi9yia6a24q2gn4gp4ns9wbmc57hjwaza3r08abig65";
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
