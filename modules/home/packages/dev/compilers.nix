{pkgs, ...}: {
  home.packages = with pkgs; [
    sqlite
    python3
    uv
    cargo
    rustc
    nodejs
  ];
}
