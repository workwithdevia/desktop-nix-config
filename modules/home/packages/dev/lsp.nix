{pkgs, ...}: {
  home.packages = with pkgs; [
    tree-sitter
    pkg-config
    wrapGAppsHook4
    cargo-tauri
  ];
}
