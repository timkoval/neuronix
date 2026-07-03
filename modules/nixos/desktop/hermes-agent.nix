{
  hermes-agent,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.services.hermes-agent;
  stateDir = cfg.stateDir or "/var/lib/hermes";
  hermesHome = "${stateDir}/.hermes";
in {
  imports = [
    hermes-agent.nixosModules.default
  ];

  options.services.hermes-agent.extraGroupWritableDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = ["/home/user/projects"];
    description = "Directories to keep group-writable by the hermes group. Useful for project directories mounted into the container via extraVolumes.";
  };

  config = {
    # Default LLM model. Hosts override by re-setting the same path
    # (the upstream deepConfigType merges via recursiveUpdate — last value wins).
    services.hermes-agent.settings.model.default = "anthropic/claude-sonnet-4";

    # Makes the `hermes` CLI available globally.
    services.hermes-agent.addToSystemPackages = lib.mkDefault true;

    # Auto-derive from container.extraVolumes, but allow per-host override.
    services.hermes-agent.extraGroupWritableDirs = lib.mkDefault (
      lib.optionals (cfg.container.enable or false) (
        let
          vols = cfg.container.extraVolumes or [];
          hostPath = v: lib.head (lib.splitString ":" v);
        in
          lib.filter (d: lib.hasPrefix "/" d) (map hostPath vols)
      )
    );

    # ── Unified permission fix (replaces old broken path watcher) ─────────
    # The old hermes-perms-fix used a systemd.paths watcher on .hermes/,
    # which triggered on every file write → rapid-fire loop → start-limit-hit.
    # This replaces it with a timer-based service that also handles extra
    # project directories (e.g., mounted via container.extraVolumes).
    systemd.services.hermes-perms = lib.mkIf cfg.enable {
      description = "Fix hermes-accessible permissions on state and project dirs";
      serviceConfig.Type = "oneshot";
      script = let
        extraDirs = cfg.extraGroupWritableDirs;
      in ''
        # ── Hermes state directory ──────────────────────────────────
        if [ -d "${hermesHome}" ]; then
          ${pkgs.coreutils}/bin/chmod 2770 "${hermesHome}" 2>/dev/null || true
          for f in config.yaml .env auth.json; do
            if [ -f "${hermesHome}/$f" ]; then
              ${pkgs.coreutils}/bin/chmod 0640 "${hermesHome}/$f" 2>/dev/null || true
            fi
          done
          ${pkgs.findutils}/bin/find "${hermesHome}" \! -group ${cfg.group} -exec \
            ${pkgs.coreutils}/bin/chown :${cfg.group} {} + 2>/dev/null || true
          # Make all files group-readable (so tkoval in hermes group can read them)
          ${pkgs.findutils}/bin/find "${hermesHome}" -type f -exec \
            ${pkgs.coreutils}/bin/chmod g+r {} + 2>/dev/null || true
          # Make all directories group-writable (so tkoval can create subdirs, e.g. profiles/<name>/cron)
          ${pkgs.findutils}/bin/find "${hermesHome}" -type d -exec \
            ${pkgs.coreutils}/bin/chmod g+rwx {} + 2>/dev/null || true
          # Propagate container-mode into profile dirs so `hermes -p <profile>` still routes into the container.
          # Use a relative symlink so it resolves correctly inside the container (where the host path is mounted at /data).
          if [ -f "${hermesHome}/.container-mode" ]; then
            for profile_dir in "${hermesHome}/profiles"/*; do
              if [ -d "$profile_dir" ]; then
                target="$profile_dir/.container-mode"
                if [ -L "$target" ]; then
                  ${pkgs.coreutils}/bin/rm -f "$target"
                fi
                if [ ! -e "$target" ]; then
                  ${pkgs.coreutils}/bin/ln -s ../../.container-mode "$target" 2>/dev/null || true
                fi
              fi
            done
          fi
        fi
        ${lib.optionalString (extraDirs != []) ''
          # ── Project directories (mounted into container) ──────────
          for dir in ${builtins.toString extraDirs}; do
            if [ -d "$dir" ]; then
              ${pkgs.findutils}/bin/find "$dir" \! -group ${cfg.group} -exec \
                ${pkgs.coreutils}/bin/chown :${cfg.group} {} + 2>/dev/null || true
              ${pkgs.findutils}/bin/find "$dir" -type d -exec \
                ${pkgs.coreutils}/bin/chmod g+rwxs {} + 2>/dev/null || true
              ${pkgs.findutils}/bin/find "$dir" -type f -exec \
                ${pkgs.coreutils}/bin/chmod g+rw {} + 2>/dev/null || true
            fi
          done
        ''}
      '';
    };

    systemd.timers.hermes-perms = lib.mkIf cfg.enable {
      description = "Periodic permission fix for hermes directories";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1min";
      };
    };

    # ── Hermes state backup (daily auto-commit + push) ─────────────────
    systemd.services.hermes-backup = lib.mkIf cfg.enable {
      description = "Hermes Agent state backup";
      after = ["hermes-perms.service"];
      requires = ["hermes-perms.service"];
      path = [pkgs.bash pkgs.coreutils pkgs.age pkgs.git pkgs.gnutar pkgs.gzip pkgs.jq pkgs.sqlite];
      environment = {
        HERMES_HOME = "${hermesHome}";
        GIT_AUTHOR_NAME = "Hermes Backup";
        GIT_AUTHOR_EMAIL = "hermes@ai";
        GIT_COMMITTER_NAME = "Hermes Backup";
        GIT_COMMITTER_EMAIL = "hermes@ai";
      };
      serviceConfig = {
        Type = "oneshot";
        User = "tkoval";
        Group = "hermes";
        WorkingDirectory = "/home/tkoval/git-local/tk/hermes-state";
      };
      script = ''
        exec /home/tkoval/git-local/tk/hermes-state/auto-backup.sh
      '';
    };

    systemd.timers.hermes-backup = lib.mkIf cfg.enable {
      description = "Daily Hermes state backup";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
