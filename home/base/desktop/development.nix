{
  pkgs,
  pkgs-unstable,
  ...
}: {
  #############################################################
  #
  #  Basic settings for development environment
  #
  #  Please avoid to install language specific packages here(globally),
  #  instead, install them independently using dev-templates:
  #     https://github.com/the-nix-way/dev-templates
  #
  #############################################################

  home.packages = with pkgs; [
    pkgs-unstable.devbox

    # DO NOT install build tools for C/C++ and others, set it per project by devShell instead
    gnumake # used by this repo, to simplify the deployment
    jdk17   # used to run some java based tools(.jar)

    # scheme related
    guile

    # debian bootstrap
    # dpkg
    pkgs-unstable.debootstrap
    cacert
    binutils
    xorg.xauth
    xorg.xhost

    # vscode
    pkgs-unstable.vscode

    # vpn
    pkgs-unstable.strongswan

    # work
    # changed python311 with python39
    # python
    (python39.withPackages (ps:
      with ps; [
        ipython
        pandas
        requests
        pyquery
        pyyaml
      ]))

    # db related
    dbeaver
    mycli
    pgcli
    mongosh
    sqlite

    # embedded development
    minicom

    # notes
    oxipng
    git-crypt
    pkgs-unstable.obsidian

    # keyboard tools
    qmk
    qmk_hid
    # vial


    # other tools
    bfg-repo-cleaner  # remove large files from git history
    k6 # load testing tool
    mitmproxy # http/https proxy tool
    protobuf # protocol buffer compiler
    pkgs-unstable.glances # system monitor
    pkgs-unstable.qutebrowser # keyboard-first browser
    rpi-imager # iso flashing tool
    unar # unzip tool
  ];

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
