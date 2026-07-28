args: final: prev: let
  inherit (final) lib;
  # Use the flake input instead of a path literal to avoid Nix 2.24+'s
  # flake path restriction on bare path literals outside the flake tree.
  grok-build-src = args.inputs.grok-build-src;
in {
  xai-grok-pager = final.rustPlatform.buildRustPackage rec {
    pname = "xai-grok-pager";
    version = "0.2.112";
    src = grok-build-src;

    cargoLock.lockFile = grok-build-src + "/Cargo.lock";

    nativeBuildInputs = with final; [pkg-config protobuf];

    buildInputs = with final;
      [openssl zlib]
      ++ lib.optionals final.stdenv.isLinux [curl];

    cargoBuildFlags = ["-p" "xai-grok-pager-bin"];

    doCheck = false;

    meta = with lib; {
      description = "Grok Build TUI — AI-native software engineering agent";
      homepage = "https://github.com/xai/grok-build";
      license = licenses.asl20;
      mainProgram = "xai-grok-pager";
      platforms = ["x86_64-linux" "aarch64-darwin"];
    };
  };
}
