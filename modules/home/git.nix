{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Jorge Devia";
        email = "workwithdevia@gmail.com";
      };

      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";

      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --graph --oneline --decorate --all";
      };
    };
  };
}
