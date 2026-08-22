{username, ...}: {
  imports = [
    ../../modules/profiles/common-home.nix
    ../../modules/profiles/laptop-home.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.11";
  };
}
