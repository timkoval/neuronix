{pkgs, ...}: {
  home.packages = with pkgs; [
    # neovim is managed by programs.neovim in server/desktop editors modules
    git
    curl
    file
    tree
    rsync
    jq
    gnugrep
    gnused
    fzf
    fd
    (ripgrep.override {withPCRE2 = true;})
  ];

  programs = {
    eza = {
      enable = true;
      git = true;
      icons = "auto";
    };

    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        # theme is managed by Stylix
      };
    };

    fzf = {
      enable = true;
      # colors are managed by Stylix
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
