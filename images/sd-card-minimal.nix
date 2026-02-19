{lib, ...}: {
  documentation.enable = lib.mkDefault false;
  documentation.man.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;
}
