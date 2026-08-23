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
  };

  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];
}
