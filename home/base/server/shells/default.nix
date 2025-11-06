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

  programs.nushell = {
    enable = true;
    # configFile.source = ./config.nu;
    inherit shellAliases;
  };

}
