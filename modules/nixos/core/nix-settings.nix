{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  programs.nix-ld.enable = true;

  nixpkgs = {
    config = {
      permittedInsecurePackages = [
        "electron-39.8.10"
      ];
      allowUnfree = true;
    };
  };
}
