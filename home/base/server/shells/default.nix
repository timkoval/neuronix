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

      # Personal tools (opencode, etc.)
      fish_add_path -g ${opencodeBin}

      function opencode
          direnv exec $PWD ${opencodeBin}/opencode $argv
      end
    '';
  };

  programs.nushell = {
    enable = true;
    configFile.source = ./config.nu;
    shellAliases = shellAliases;
  };

}

