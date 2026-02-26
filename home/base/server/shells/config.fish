# Fish Shell Configuration
# Minimal config ported from nushell



# Vi mode
fish_vi_key_bindings

# Cursor shapes
set fish_cursor_default line
set fish_cursor_insert block
set fish_cursor_replace_one underscore
set fish_cursor_visual block

# Direnv integration
if type -q direnv
    direnv hook fish | source
end

# Note: zoxide is enabled via home-manager (enableFishIntegration = true)
# so the hook is automatically added

function opencode --wraps=opencode --description 'Run OpenCode inside devenv (works from any nested subdir)'
    # 1. Fast path: git root (99 % of projects)
    set -l root ""
    if command -q git
        set root (git rev-parse --show-toplevel 2>/dev/null)
    end

    if test -n "$root"
        if test -f "$root/devenv.nix" -o -f "$root/flake.nix" -o -f "$root/.envrc"
            if test "$root" != "$PWD"
                echo (set_color cyan)"→ Launching OpenCode inside devenv (root: $root)"(set_color normal) >&2
            end
            pushd "$root" >/dev/null
            devenv shell --command command opencode $argv
            set -l exit_code $status
            popd >/dev/null
            return $exit_code
        end
    end

    # 2. Fallback: walk up the directory tree (for non-git projects)
    set -l dir $PWD
    while test "$dir" != "/"
        if test -f "$dir/devenv.nix" -o -f "$dir/flake.nix" -o -f "$dir/.envrc"
            echo (set_color cyan)"→ Launching OpenCode inside devenv (root: $dir)"(set_color normal) >&2
            pushd "$dir" >/dev/null
            devenv shell --command command opencode $argv
            set -l exit_code $status
            popd >/dev/null
            return $exit_code
        end
        set dir (dirname "$dir")
    end

    # 3. No devenv found anywhere -> run the real opencode normally
    command opencode $argv
end
