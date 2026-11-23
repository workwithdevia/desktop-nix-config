{
  description = "nix-config with explicit NixOS/Home Manager module layers";

  inputs = {
    # ==========================================================
    # NIXPKGS
    # ==========================================================

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # ==========================================================
    # HOME MANAGER
    # ==========================================================

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # ==========================================================
    # DANK MATERIAL SHELL
    # ==========================================================

    dms = {
      url = "github:duxlabs-dev/dux-shell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-plugin-registry = {
      url = "github:duxlabs-dev/dux-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    danksearch = {
      url = "github:duxlabs-dev/dux-search";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankcalendar = {
      url = "github:duxlabs-dev/dux-calendar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================
    # NUR
    # ==========================================================

    nur.url = "github:nix-community/NUR";

    # ==========================================================
    # WINAPPS
    # ==========================================================

    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================
    # SECRETS
    # ==========================================================

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================
    # ZSH TOOLS
    # ==========================================================

    ohmyzsh = {
      url = "github:ohmyzsh/ohmyzsh";
      flake = false;
    };

    zsh-autosuggestions = {
      url = "github:zsh-users/zsh-autosuggestions";
      flake = false;
    };

    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };

    powerlevel10k = {
      url = "github:romkatv/powerlevel10k";
      flake = false;
    };

    zsh-history-substring-search = {
      url = "github:zsh-users/zsh-history-substring-search";
      flake = false;
    };

    zsh-select = {
      url = "github:z-shell/zsh-select";
      flake = false;
    };

    zsh-autoswitch-conda = {
      url = "github:rappdw/zsh-autoswitch-conda";
      flake = false;
    };

    zsh-system-clipboard = {
      url = "github:kutsan/zsh-system-clipboard";
      flake = false;
    };

    parso-py315 = {
      url = "github:davidhalter/parso/512e78c1a8f4968086af652394a9cd0a91c16e54";
      flake = false;
    };

    jiter = {
      url = "github:pydantic/jiter/v0.18.0";
      flake = false;
    };
  };

  outputs = inputs:
    import ./flake/outputs.nix inputs;
}
