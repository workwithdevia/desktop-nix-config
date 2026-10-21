{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 1d";
    };
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
