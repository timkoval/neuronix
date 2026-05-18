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

  # Default LLM model. Override per-host as needed.
  services.hermes-agent.settings.model.default = lib.mkDefault "anthropic/claude-sonnet-4";

  # Makes the `hermes` CLI available globally.
  services.hermes-agent.addToSystemPackages = lib.mkDefault true;
}
