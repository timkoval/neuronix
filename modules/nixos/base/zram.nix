{
  config,
  lib,
  ...
}: let
  cfg = config.neuronix.zram;
in {
  options.neuronix.zram.enable = lib.mkEnableOption "zram swap";

  config = lib.mkMerge [
    {
      neuronix.zram.enable = lib.mkDefault true;
    }
    (lib.mkIf cfg.enable {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        priority = 5;
        memoryPercent = 50;
      };
    })
  ];
}
