{ pkgs, config, ... }: let
  shellAliases = {
    k = "kubectl";
    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };

  localBin   = "${config.home.homeDirectory}/.local/bin";
  rustBin    = "${config.home.homeDirectory}/.cargo/bin";
  npmBin     = "${config.home.homeDirectory}/.npm/bin";
  opencodeBin = "${config.home.homeDirectory}/.opencode/bin";
in {
  home.sessionPath = [
    opencodeBin
    localBin
    rustBin
    npmBin
  ];

  home.shellAliases = shellAliases;

  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Keep these (you need them when fish is launched directly by Ghostty/kitty etc.)
      fish_add_path -g /etc/profiles/per-user/$USER/bin
      fish_add_path -g /nix/var/nix/profiles/default/bin
      fish_add_path -g /run/current-system/sw/bin
      fish_add_path -g /opt/homebrew/bin
      fish_add_path -g /usr/local/bin

      # Your custom opencode wrapper (unchanged)
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
              devenv shell -- command opencode $argv
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
                  devenv shell -- command opencode $argv
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
    inherit shellAliases;
  };
}
