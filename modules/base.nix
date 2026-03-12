{
  pkgs,
  hostVars,
  nuenv,
  ...
} @ args: {
  # ── Stylix: system-wide theming via base16 ──────────────────────────────
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-light-medium.yaml";
    polarity = "light";

    # A wallpaper image is required by Stylix (especially on NixOS).
    # Use a simple solid-color placeholder; the base16 scheme defines the palette.
    image = pkgs.runCommand "wallpaper.png" { nativeBuildInputs = [pkgs.imagemagick]; } ''
      magick -size 1920x1080 xc:#fbf1c7 $out
    '';

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      serif = {
        package = pkgs.source-han-serif;
        name = "Source Han Serif SC";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };

    # Per-app target overrides are set in home-manager modules where needed.
    # Neovim theming is disabled in the neovim HM module since it's managed by neuronvim.
  };

  nixpkgs.overlays =
    [
      nuenv.overlays.default
    ]
    ++ (import ../overlays args);

  users.users.${hostVars.username} = {
    description = hostVars.userfullname;
    # Public Keys that can be used to login to all my PCs, Macbooks, and servers.
    #
    # Since its authority is so large, we must strengthen its security:
    # 1. The corresponding private key must be:
    #    1. Generated locally on every trusted client via:
    #      ```bash
    #      # KDF: bcrypt with 256 rounds, takes 2s on Apple M2):
    #      # Passphrase: digits + letters + symbols, 12+ chars
    #      ssh-keygen -t ed25519 -a 256 -C "ryan@xxx" -f ~/.ssh/xxx`
    #      ```
    #    2. Never leave the device and never sent over the network.
    # 2. Or just use hardware security keys like Yubikey/CanoKey.
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKlN+Q/GxvwxDX/OAjJHaNFEznEN4Tw4E4TwqQu/eD6 ryan@idols-ai"
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPoa9uEI/gR5+klqTQwvCgD6CD5vT5iD9YCNx2xNrH3B ryan@fern"
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPwZ9MdotnyhxIJrI4gmVshExHiZOx+FGFhcW7BaYkfR ryan@harmonica"
    ];
  };

  nix.settings = {
    # enable flakes globally
    experimental-features = ["nix-command" "flakes"];

    # given the users in this list the right to specify additional substituters via:
    #    1. `nixConfig.substituers` in `flake.nix`
    #    2. command line args `--options substituers http://xxx`
    trusted-users = [hostVars.username];

    # substituers that will be considered before the official ones(https://cache.nixos.org)
    substituters = [
      # cache mirror located in China
      # status: https://mirror.sjtu.edu.cn/
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
      # status: https://mirrors.ustc.edu.cn/status/
      "https://anyrun.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"

      "https://nix-community.cachix.org"
      # my own cache server
      # "https://ryan4yin.cachix.org"
    ];

    trusted-public-keys = [
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = true;
  };
}
