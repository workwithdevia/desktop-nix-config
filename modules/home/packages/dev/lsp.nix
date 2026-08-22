{pkgs, ...}: {
  home.packages = with pkgs; [
    tree-sitter
    lua-language-server
    nil
    pkg-config
    wrapGAppsHook4
    cargo-tauri
  ];
}
