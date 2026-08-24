{username, ...}: {
  imports = [
    ../../modules/profiles/common-home.nix
    ../../modules/profiles/desktop-home.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.11";
  };

  sops.defaultSopsFile = ./secrets.yaml;
}
