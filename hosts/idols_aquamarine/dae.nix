# https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/networking/dae.nix
{
  services.dae = {
    enable = true;
    openFirewall = {
      enable = true;
      port = 12345;
    };
    configFile = ./bypass-router.dae;
  };
}
