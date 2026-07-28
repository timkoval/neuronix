args: final: prev: let
  inherit (final) lib;
  # The grok-build repo now has its own flake.nix that defines the
  # xai-grok-pager package.  Access it via the flake input (available
  # through the NixOS module args, which include `inputs` via specialArgs).
  grok-build-src = args.inputs.grok-build-src;
  system = final.stdenv.hostPlatform.system;
in {
  xai-grok-pager = grok-build-src.packages.${system}.xai-grok-pager;
}
