{
  pkgs,
  nur-ryan4yin,
  ...
}: {
  # replacement of htop/nmon
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "gruvbox_light";
      theme_background = false; # make btop transparent
    };
  };
}
