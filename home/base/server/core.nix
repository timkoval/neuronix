{
  pkgs,
  pkgs-unstable,
  nur-ryan4yin,
  nur-timkoval,
  ...
}: {
  imports = [
    ../minimal
  ];

  home.packages = with pkgs; [
    neofetch
    ranger # terminal file manager(batteries included, with image preview support)
    atuin # shell history sync

    colmena

    # networking tools
    mtr # A network diagnostic tool
    iperf3
    dnsutils # `dig` + `nslookup`
    ldns # replacement of `dig`, it provide the command `drill`
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
    nmap # A utility for network discovery and security auditing
    ipcalc # it is a calculator for the IPv4/v6 addresses

    # archives
    zip
    xz
    unzip
    p7zip

    # misc
    tldr
    cowsay
    findutils
    which
    gnutar
    zstd
    gnupg

    # Text Processing
    # Docs: https://github.com/learnbyexample/Command-line-text-processing

    gnumake
    gawk # GNU awk, a pattern scanning and processing language

    # morden cli tools, replacement of grep/sed/...

    # A fast and polyglot tool for code searching, linting, rewriting at large scale
    # supported languages: only some mainstream languages currently(do not support nix/nginx/yaml/toml/...)
    ast-grep

    sad # CLI search and replace, just like sed, but with diff preview.
    yq-go # yaml processer https://github.com/mikefarah/yq
    just # a command runner like make, but simpler
    delta # A viewer for git and diff output
    lazygit # Git terminal UI.
    hyperfine # command-line benchmarking tool
    gping # ping, but with a graph(TUI)
    doggo # DNS client for humans
    duf # Disk Usage/Free Utility - a better 'df' alternative
    dust # A more intuitive version of `du` in rust
    # ncdu # analyzer your disk usage Interactively, via TUI(replacement of `du`)
    gdu # disk usage analyzer(replacement of `du`)
    act # github actions testing tool

    # nix related
    #
    # it provides the command `nom` works just like `nix
    # with more details log output
    nix-output-monitor

    # productivity
    caddy # A webserver with automatic HTTPS via Let's Encrypt(replacement of nginx)
    croc # File transfer between computers securely and easily
    glow # markdown previewer in terminal
    md-tui
    pkgs-unstable.github-copilot-cli # GitHub Copilot CLI tool
    # nur-timkoval.packages.${pkgs.system}.openspec  # Commented out for servers - requires network access during build
  ];

  programs = {
    # Atuin replaces your existing shell history with a SQLite database,
    # and records additional context for your commands.
    # Additionally, it provides optional and fully encrypted
    # synchronisation of your history between machines, via an Atuin server.
    atuin = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
