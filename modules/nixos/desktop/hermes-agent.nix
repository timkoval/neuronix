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
  # Hermes Agent — LLM agent from Nous Research
  # Docs: https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup
  imports = [
    hermes-agent.nixosModules.default
  ];

  # Default LLM model. Hosts override by re-setting the same path
  # (the upstream deepConfigType merges via recursiveUpdate — last value wins).
  services.hermes-agent.settings.model.default = "anthropic/claude-sonnet-4";

  # Makes the `hermes` CLI available globally.
  services.hermes-agent.addToSystemPackages = lib.mkDefault true;

  # ── Auto-heal permissions ─────────────────────────────────────────────
  # `hermes auth` (and a few other interactive commands) reset
  # /var/lib/hermes/.hermes to mode 0700, breaking group access for the
  # hostUsers. This watcher re-applies the module's intended perms
  # (2770 on the dir, 0640 on config.yaml/.env) whenever the dir changes.
  systemd.services.hermes-perms-fix = lib.mkIf cfg.enable {
    description = "Restore group-accessible permissions on hermes state directory";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "hermes-perms-fix" ''
        ${pkgs.coreutils}/bin/chmod 2770 ${hermesHome} 2>/dev/null || true
        ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${hermesHome} 2>/dev/null || true
        for f in config.yaml .env auth.json; do
          if [ -f "${hermesHome}/$f" ]; then
            ${pkgs.coreutils}/bin/chmod 0640 "${hermesHome}/$f" 2>/dev/null || true
            ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} "${hermesHome}/$f" 2>/dev/null || true
          fi
        done
      '';
    };
  };

  systemd.paths.hermes-perms-fix = lib.mkIf cfg.enable {
    description = "Watch hermes state directory for permission drift";
    wantedBy = ["multi-user.target"];
    pathConfig = {
      PathModified = hermesHome;
      Unit = "hermes-perms-fix.service";
    };
  };
}
