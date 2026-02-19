{
  config,
  lib,
  ...
}: let
  cfg = config.neuronix.docker;
in {
  ###################################################################################
  #
  #  Virtualisation - Libvirt(QEMU/KVM) / Docker / LXD / WayDroid
  #
  ###################################################################################

  options.neuronix.docker.enable = lib.mkEnableOption "Docker runtime";

  config = lib.mkMerge [
    {
      neuronix.docker.enable = lib.mkDefault true;
      virtualisation = {
        waydroid.enable = false;
        lxd.enable = false;
      };
    }
    (lib.mkIf cfg.enable {
      virtualisation.docker = {
        enable = true;
        daemon.settings = {
          # enables pulling using containerd, which supports restarting from a partial pull
          # https://docs.docker.com/storage/containerd/
          "features" = {"containerd-snapshotter" = true;};
        };

        # start dockerd on boot.
        # This is required for containers which are created with the `--restart=always` flag to work.
        enableOnBoot = true;
      };
    })
  ];
}
