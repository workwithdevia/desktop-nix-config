{pkgs, ...}: {
  home.packages = with pkgs; [
    nmap
    traceroute
  ];
}
