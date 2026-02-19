{ pkgs, ... }: {
  xdg.configFile."ghostty/config".text = ''
    theme = "Gruvbox Light"
    font-family = "ZedMono Nerd Font Mono"
    font-size = 14
    window-decoration = false
    background-opacity = 0.93
    command = "${pkgs.fish}/bin/fish"
  '';
}
