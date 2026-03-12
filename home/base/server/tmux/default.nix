{ config, pkgs, ... }:
let
  shellAliases = {
    "t" = "tmux";
  };
in {
  programs.tmux = {
    enable = true;
    # Theme is managed by Stylix
    plugins = with pkgs;
      [
        {
          plugin = tmuxPlugins.vim-tmux-navigator;
          extraConfig = ''
            set -g @tmux_navigator_no_mappings 'true'
            '';
        }
      ];
    extraConfig = ''
      set-option -g default-shell ${pkgs.fish}/bin/fish
      set-option -g default-command "${pkgs.fish}/bin/fish -i"

      unbind r
      bind r   source-file ${config.xdg.configHome}/tmux/tmux.conf

      set -g prefix C-s
      set -g mouse on

      # Unbind any no-prefix arrow keys to avoid conflicts
      unbind -n Up
      unbind -n Down
      unbind -n Left
      unbind -n Right

      bind Up    select-pane -U
      bind Down  select-pane -D
      bind Left  select-pane -L
      bind Right select-pane -R

      set -g status-position top

      '';
  };
  # only works in bash/zsh/fish, not nushell
  home.shellAliases = shellAliases;

}
