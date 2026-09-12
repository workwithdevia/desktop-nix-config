{pkgs, ...}: {
  users.users.workwithdevia = {
    isNormalUser = true;
    description = "Jorge Devia";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDOoIWIxsJVrYb9JJhHRZBBpza8jEbj/vKu/pOXh9iR root@nixos"
    ];
  };

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
}
