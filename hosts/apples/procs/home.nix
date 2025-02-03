{
  programs.ssh = {
    enable = true;
    extraConfig = ''
    '';
  };

  modules.editors.emacs = {
    enable = false;
  };
}
