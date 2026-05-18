{
  config,
  pkgs,
  ...
}: let
  shellAliases = {
    "t" = "tmux";
  };
in {
  programs.tmux = {
    enable = true;
    # Theme is managed by Stylix
    plugins = with pkgs; [
      {
        plugin = tmuxPlugins.vim-tmux-navigator;
        extraConfig = ''
          set -g @tmux_navigator_no_mappings 'true'
        '';
      }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
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

      # Vi-style throughout tmux: copy mode + command prompt
      set -g mode-keys vi
      set -g status-keys vi
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"

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

      # ── Status bar: keep Stylix session badge on left, ──────────────
      # ── add mode + working directory + time on the right ────────────
      set -g status-interval 2

      # Left: session name + mode badge (NORMAL / COPY / PREFIX).
      # Theme-agnostic: bold session, reverse-video badge for the mode.
      set -g status-left-length 60
      set -g status-left "#[bold] #S #[default]#{?client_prefix,#[reverse] PREFIX #[noreverse],#{?pane_in_mode,#[reverse] COPY #[noreverse], NORMAL }} "

      # Right: working directory + clock (replaces Stylix's date+hostname).
      set -g status-right-length 80
      set -g status-right " 󰉋 #{b:pane_current_path}  󰥔 #(date +'%H:%M') "
    '';
  };
  # only works in bash/zsh/fish, not nushell
  home.shellAliases = shellAliases;
}
