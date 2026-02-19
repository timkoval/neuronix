{lib, ...}: {
  imports = [
    ./minimal.nix
  ];

  neuronix = {
    docker.enable = lib.mkOverride 900 false;
    networking.avahi.enable = lib.mkOverride 900 false;
    packages.extended.enable = lib.mkOverride 900 false;
    power.enable = lib.mkOverride 900 false;
    zram.enable = lib.mkOverride 900 true;
    btrbk.enable = lib.mkOverride 900 false;
  };

  documentation.enable = lib.mkDefault false;
  xdg = {
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
  };
}
