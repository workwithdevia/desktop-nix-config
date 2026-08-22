{pkgs, ...}: {
  home.packages = with pkgs; [
    grim
    slurp
    wf-recorder
    wl-mirror
    wl-clipboard
  ];
}
