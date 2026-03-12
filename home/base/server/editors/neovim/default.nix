{pkgs, ...}: {
  # Neovim theme is managed externally, not by Stylix
  stylix.targets.neovim.enable = false;

  programs = {
    neovim = {
      enable = true;

      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
