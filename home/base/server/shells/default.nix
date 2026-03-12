{ pkgs, config, ... }: let
  shellAliases = {
    k = "kubectl";

    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };

  localBin = "${config.home.homeDirectory}/.local/bin";
  rustBin = "${config.home.homeDirectory}/.cargo/bin";
  npmBin = "${config.home.homeDirectory}/.npm/bin";
  opencodeBin = "${config.home.homeDirectory}/.opencode/bin";
in {
  # only works in bash/zsh, not nushell
  home.shellAliases = shellAliases;


  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:${localBin}:${rustBin}:${npmBin}:${opencodeBin}"
    '';
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Ensure nix profile paths are available early
      # Needed for atuin, zoxide, and other nix-installed tools
      # when fish is launched directly by terminals (ghostty, kitty, etc.)
      set -gx PATH /etc/profiles/per-user/$USER/bin $PATH
      set -gx PATH /nix/var/nix/profiles/default/bin $PATH
      set -gx PATH /run/current-system/sw/bin $PATH

      function opencode --wraps=opencode --description 'Run OpenCode inside devenv (works from any nested subdir)'
          # 1. Fast path: git root (most projects)
          set -l root ""
          if command -q git
              set root (git rev-parse --show-toplevel 2>/dev/null)
          end

          if test -n "$root" -a \( -f "$root/devenv.nix" -o -f "$root/flake.nix" -o -f "$root/.envrc" \)
              if test "$root" != $PWD
                  echo (set_color cyan)"→ Launching OpenCode inside devenv (root: $root)"(set_color normal) >&2
              end
              pushd "$root" >/dev/null
              devenv shell -- command opencode $argv   # ← this is the only changed line
              set -l exit_code $status
              popd >/dev/null
              return $exit_code
          end

          # 2. Fallback: walk up the directory tree
          set -l dir $PWD
          while test "$dir" != /
              if test -f "$dir/devenv.nix" -o -f "$dir/flake.nix" -o -f "$dir/.envrc"
                  echo (set_color cyan)"→ Launching OpenCode inside devenv (root: $dir)"(set_color normal) >&2
                  pushd "$dir" >/dev/null
                  devenv shell -- command opencode $argv   # ← this is the only changed line
                  set -l exit_code $status
                  popd >/dev/null
                  return $exit_code
              end
              set dir (dirname "$dir")
          end

          # 3. No devenv found → run normal opencode
          command opencode $argv
      end
    '';
  };

  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    shellAliases = shellAliases;
  };

}

