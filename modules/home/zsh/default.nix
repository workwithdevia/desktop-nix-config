{inputs, ...}: {
  home.file = {
    ".zshrc".source = ./config/zshrc;
    ".p10k.zsh".source = ./config/p10k.zsh;
    ".zprofile".source = ./config/zprofile;
    ".zshenv".source = ./config/zshenv;

    ".oh-my-zsh".source = inputs.ohmyzsh;
    ".zsh-plugins/zsh-autosuggestions".source = inputs.zsh-autosuggestions;
    ".zsh-plugins/zsh-syntax-highlighting".source = inputs.zsh-syntax-highlighting;
    "powerlevel10k".source = inputs.powerlevel10k;
    ".zsh-plugins/zsh-history-substring-search".source = inputs.zsh-history-substring-search;
    ".zsh-plugins/zsh-select".source = inputs.zsh-select;
    ".zsh-plugins/zsh-autoswitch-conda".source = inputs.zsh-autoswitch-conda;
    ".zsh-plugins/zsh-system-clipboard".source = inputs.zsh-system-clipboard;
    ".zsh-plugins/ohmyzsh".source = inputs.ohmyzsh;
  };
}
