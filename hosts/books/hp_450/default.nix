{
  config,
  lib,
  pkgs,
  hostVars,
  ...
} @ args:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # ../../secrets/nixos.nix
  ];

  nixpkgs.overlays = import ../../../overlays args;

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    systemd-boot.enable = true;
  };

  boot.initrd.enable = true;
  boot.supportedFilesystems = ["btrfs"];

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [];

  boot.kernelParams = [];
  boot.resumeDevice = "/dev/disk/by-uuid/c8105d09-54e7-4098-b8ff-c9e3a9c82813";

  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowSuspendThenHibernate=yes
    HibernateDelaySec=30min
  '';

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };
  services.power-profiles-daemon = {
    enable = lib.mkForce false;
  };
  services.tlp = {
    enable = true;
    settings = {
      # CPU: let intel_pstate HWP handle frequency scaling,
      # only set energy performance policy hints
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Battery driver: only native ACPI (HP does not support ThinkPad drivers)
      NATACPI_ENABLE = 1;
      TPACPI_ENABLE = 0;
      TPSMAPI_ENABLE = 0;
    };
  };

  services.thermald.enable = true;
  services.fwupd.enable = true;

  networking = {
    hostName = hostVars.hostname;
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
