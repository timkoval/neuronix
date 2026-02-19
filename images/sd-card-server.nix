{lib, ...}: {
  documentation.enable = lib.mkDefault false;
  services.logrotate.checkConfig = lib.mkDefault false;
}
