{pkgs, ...}: {
  home.packages = with pkgs; [
    gcc
    sqlite
    python3
    uv
    cargo
    rustc
    nodejs
    direnv
  ];
}
