{pkgs, ...}: {
  home.packages = with pkgs; [
    neovim
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
      icons = true;
    };

    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "gruvbox-light";
      };
    };

    fzf = {
      enable = true;
      colors = {
        "bg+" = "#313244";
        "bg" = "#1e1e2e";
        "spinner" = "#f5e0dc";
        "hl" = "#f38ba8";
        "fg" = "#cdd6f4";
        "header" = "#f38ba8";
        "info" = "#cba6f7";
        "pointer" = "#f5e0dc";
        "marker" = "#f5e0dc";
        "fg+" = "#cdd6f4";
        "prompt" = "#cba6f7";
        "hl+" = "#f38ba8";
      };
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
