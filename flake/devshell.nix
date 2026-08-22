{pkgs}:
pkgs.mkShell {
  packages = with pkgs; [
    # ==========================================================
    # FORMAT & LINT
    # ==========================================================

    alejandra
    deadnix
    statix

    # ==========================================================
    # GIT HOOKS & COMMIT VALIDATION
    # ==========================================================

    prek
    commitlint

    # ==========================================================
    # NIX LANGUAGE SERVERS
    # ==========================================================

    nil
    nixd

    # ==========================================================
    # DEVELOPMENT ENVIRONMENT
    # ==========================================================

    direnv
    nix-direnv

    git
    zsh

    # ==========================================================
    # NIX TOOLS
    # ==========================================================

    nix-output-monitor
    nvd

    # ==========================================================
    # BUILD & DEPLOY
    # ==========================================================

    gnumake
    nixos-rebuild
    colmena

    # ==========================================================
    # SECRETS
    # ==========================================================

    sops
    age
    ssh-to-age
  ];

  shellHook = ''
    echo ""
    echo "❄️  NixOS Dotfiles development environment"
    echo ""

    echo "Available tools:"
    echo "  alejandra  $(alejandra --version 2>/dev/null || true)"
    echo "  statix     $(statix --version 2>/dev/null || true)"
    echo "  deadnix    $(deadnix --version 2>/dev/null || true)"
    echo "  prek       $(prek --version 2>/dev/null || true)"
    echo "  nix        $(nix --version)"
    echo ""
  '';
}
