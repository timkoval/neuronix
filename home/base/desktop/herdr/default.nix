{
  # the herdr package itself is installed in ../dev-tools.nix
  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
