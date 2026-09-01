{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep
    fzf
    bat
    tree
    fd
    lsd
    zoxide
    lazygit
    yazi
    btop
    jq
    unzip
    unrar
    p7zip
    lsof
    direnv
  ];
}
