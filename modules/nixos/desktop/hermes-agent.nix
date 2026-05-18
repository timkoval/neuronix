{
  hermes-agent,
  pkgs,
  lib,
  config,
  ...
}: {
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
}
