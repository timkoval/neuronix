{config, ...}: {
  programs.ssh = {
    enable = true;
    extraConfig = ''
    '';
    matchBlocks."github.com".identityFile = "${config.home.homeDirectory}/.ssh/${config.host.variables.hostname}";
  };

  modules.editors.emacs = {
    enable = false;
  };
}
