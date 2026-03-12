{ pkgs, ... }: {
  xdg.configFile."ghostty/config".text = ''
    font-family = "ZedMono Nerd Font Mono"
    font-size = 14
    window-decoration = false
    background-opacity = 0.93
    command = "${pkgs.fish}/bin/fish"
  '';
  # theme is managed by Stylix
}
