{ config, pkgs, ... }:
let
  shellAliases = {
    "t" = "tmux";
  };
in {
  programs.tmux = {
    enable = true;
    plugins = with pkgs;
      [
        # must be before continuum edits right status bar
        {
          plugin = tmuxPlugins.gruvbox;
          extraConfig = '' 
            set -g @tmux-gruvbox 'light'
          '';
        }
        {
          plugin = tmuxPlugins.vim-tmux-navigator;
          extraConfig = ''
            set -g @tmux_navigator_no_mappings 'true'
            '';
        }
      ];
    extraConfig = ''
      set-option -g default-shell ${pkgs.nushell}/bin/nu
      set-option -g default-command "${pkgs.nushell}/bin/nu -i"

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
  # only works in bash/zsh, not nushell
  home.shellAliases = shellAliases;
  programs.nushell.shellAliases = shellAliases;

}
