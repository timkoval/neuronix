{
  config,
  lib,
  ...
}: let
  cfg = config.neuronix.btrbk;
in {
  options.neuronix.btrbk.enable = lib.mkEnableOption "btrbk snapshot service";

  config = lib.mkMerge [
    {
      neuronix.btrbk.enable = lib.mkDefault true;
    }
    (lib.mkIf cfg.enable {
      services.btrbk.instances.btrbk = {
        onCalendar = "Tue,Sat *-*-* 3:45:20";
        settings = {
          snapshot_preserve = "7d";
          snapshot_preserve_min = "2d";

          target_preserve = "9d 4w 2m";
          target_preserve_min = "no";

          volume = {
            "/btr_pool" = {
              subvolume = {
                "@persistent" = {
                  snapshot_create = "always";
                };
              };
            };
          };
        };
      };
    })
  ];
}
