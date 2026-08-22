{pkgs, ...}: {
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    fira-code
    font-awesome
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
}
