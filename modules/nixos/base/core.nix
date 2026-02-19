{
  lib,
  pkgs,
  ...
}: {
  # to install chrome, you need to enable unfree packages
  nixpkgs.config.allowUnfree = lib.mkForce true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = true;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
    git
  ];

  environment.variables.EDITOR = "nvim";
}
