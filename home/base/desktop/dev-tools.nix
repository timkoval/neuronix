{
  pkgs,
  pkgs-unstable,
  ghostty,
  devenv,
  ...
}: let
  # xai-grok-pager comes from the grok-build overlay, which is loaded via
  # `nixpkgs.overlays` in the NixOS config (hosts/boxes/ai/default.nix) and
  # automatically propagated to home-manager through useGlobalPkgs.
  # No manual pkgs.extend needed.
  xai-grok-pager = pkgs.xai-grok-pager;
  # nixpkgs-unstable is pinned before herdr's Darwin build fix (nixpkgs
  # 39b5c834a, "herdr: fix Darwin builds", 2026-07-03). Without it, the
  # vendored libghostty-vt zig build has no xcrun/xcode-select to locate the
  # SDK (error.DarwinSdkNotFound) and no libtool to archive the static lib.
  # Drop this override once nixpkgs-unstable is bumped past that commit.
  # (bound outside `with pkgs` so it is unambiguous)
  herdrPkg =
    if pkgs.stdenv.isDarwin
    then
      pkgs-unstable.herdr.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [])
          ++ [pkgs-unstable.cctools pkgs-unstable.xcbuild];
      })
    else pkgs-unstable.herdr;
in {
  #############################################################
  #
  #  Basic settings for development environment
  #
  #  Please avoid to install language specific packages here(globally),
  #  instead, install them:
  #     1. per IDE, such as `programs.neovim.extraPackages`
  #     2. per-project, using https://github.com/the-nix-way/dev-templates
  #
  #############################################################

  home.packages =
    (with pkgs; [
      devenv.packages."${pkgs.system}".default

      # db related
      # mycli
      pgcli
      mongosh
      sqlite

      # embedded development
      minicom

      # agent tooling
      herdrPkg # agent multiplexer that lives in your terminal

      # Grok Build TUI (from local source, via grok-build overlay)
      xai-grok-pager
    ])
    ++ (with pkgs; [
      # ai related
      # python311Packages.huggingface-hub # huggingface-cli

      # python tooling
      uv # fast Python package manager (replaces pip/poetry/pyenv)

      # misc
      gh # GitHub CLI
      glab # GitLab CLI
      bfg-repo-cleaner # remove large files from git history
      protobuf # protocol buffer compiler
      nix-init # generate nix package from url
      glances # system monitor
      unar # unzip tool
      qmk # keyboard firmware development
      pkgs-unstable.python313Packages.oathtool # generate TOTP codes
      openconnect # openconnect client for Cisco VPN

      # solve coding extercises - learn by doing
      leetcode-cli
      exercism
      ghostty
    ])
    ++ (
      if pkgs.stdenv.isLinux
      then
        (with pkgs; [
          # Automatically trims your branches whose tracking remote refs are merged or gone
          # It's really useful when you work on a project for a long time.
          git-trim

          # need to run `conda-install` before using it
          # need to run `conda-shell` before using command `conda`
          # conda is not available for MacOS
          # conda

          # mitmproxy # http/https proxy tool
          # insomnia # REST client
          # wireshark # network analyzer
        ])
      else []
    );

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;

      enableZshIntegration = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
