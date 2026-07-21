{
  config,
  lib,
  ...
}: let
  cfg = config.neuronix.earlyoom;
in {
  options.neuronix.earlyoom.enable = lib.mkEnableOption "earlyoom out-of-memory guard";

  config = lib.mkIf cfg.enable {
    # Kills the biggest memory consumer well before the kernel OOM killer
    # would kick in, so runaway processes (e.g. rust-analyzer on a huge
    # workspace) get reaped instead of stalling the whole system to a freeze.
    services.earlyoom = {
      enable = true;
      enableNotifications = true;

      # SIGTERM once free mem/swap drops below 10%, SIGKILL below 5%.
      freeMemThreshold = 10;
      freeSwapThreshold = 10;

      extraArgs = [
        # Never touch the session/compositor or remote access, even if they
        # briefly spike in RSS.
        "--avoid"
        "^(systemd.*|sshd|NetworkManager|wpa_supplicant|dbus-daemon|dbus-broker|polkitd|Xorg|Xwayland|[Hh]yprland|niri|greetd|pipewire.*|wireplumber)$"
        # Prefer killing language servers / dev tooling first — they lose
        # no user data and just restart on next use.
        "--prefer"
        "(^|/)(rust-analyzer|pyright|zls|nil|clangd|gopls|jdtls|ccls|.*-language-server)$"
      ];
    };
  };
}
