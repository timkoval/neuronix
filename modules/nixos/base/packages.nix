{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.neuronix.packages.extended;
in {
  options.neuronix.packages.extended.enable = lib.mkEnableOption "extended base system packages";

  config = lib.mkMerge [
    {
      neuronix.packages.extended.enable = lib.mkDefault true;
    }
    (lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        parted
        psmisc
        aria2
        git-lfs
        (
          let
            base = pkgs.appimageTools.defaultFhsEnvArgs;
          in
            pkgs.buildFHSUserEnv (base
              // {
                name = "fhs";
                targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [pkgs.pkg-config];
                profile = "export FHS=1";
                runScript = "bash";
                extraOutputsToInstall = ["dev"];
              })
        )
      ];
    })
  ];
}
