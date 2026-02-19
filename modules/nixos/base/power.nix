{
  config,
  lib,
  ...
}: let
  cfg = config.neuronix.power;
in {
  options.neuronix.power.enable = lib.mkEnableOption "power management services";

  config = lib.mkIf cfg.enable {
    services = {
      power-profiles-daemon.enable = true;
      upower.enable = true;
    };
  };
}
