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
