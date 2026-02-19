{
  config,
  lib,
  hostVars,
  ...
}: {
  options.neuronix.networking.avahi.enable = lib.mkEnableOption "Avahi mDNS service";

  config = lib.mkMerge [
    {
      networking.firewall.enable = lib.mkDefault false;

      # programs.ssh = hostVars.networking.ssh; TODO: fix assignment
      services.openssh = {
        enable = true;
        settings = {
          X11Forwarding = true;
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
        openFirewall = true;
      };
    }
    (lib.mkIf config.neuronix.networking.avahi.enable {
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          domain = true;
          userServices = true;
        };
      };
    })
  ];
}
