{grok-build-src}: final: prev: let
  system = final.stdenv.hostPlatform.system;
in {
  xai-grok-pager = grok-build-src.packages.${system}.xai-grok-pager;
}
