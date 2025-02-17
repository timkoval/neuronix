let
  desktop_base_modules = {
    nixos-modules = [
      ../secrets/nixos.nix
      ../modules/nixos/desktop.nix
    ];
    home-module.imports = [
      ../home/linux/desktop.nix
    ];
  };
in {
    # Ai
    ai_modules_hyprland = {
      nixos-modules =
        [
          ../hosts/boxes/ai
          {modules.desktop.wayland.enable = true;}
        ]
        ++ desktop_base_modules.nixos-modules;
      home-module.imports =
        [
          ../hosts/boxes/ai/home.nix
          {modules.desktop.hyprland.enable = true;}
        ]
        ++ desktop_base_modules.home-module.imports;
    };

    # Cloud Hetzner TK
    cloud_hetzner_tk_modules = {
      nixos-modules =
        [
          ../secrets/nixos.nix
          ../modules/nixos/server/server.nix
          ../hosts/clouds/hetzner
        ];
      home-module.imports =
        [
          ../home/linux/server.nix
        ];
    };
    cloud_hetzner_tk_tags = ["hetzner"];

    # Book HP 450
    book_hp_450_modules_hyprland = {
      nixos-modules =
        [
          ../hosts/books/hp_450
          {modules.desktop.wayland.enable = true;}
        ]
        ++ desktop_base_modules.nixos-modules;
      home-module.imports =
        [
          ../hosts/books/hp_450/home.nix
          {modules.desktop.hyprland.enable = true;}
        ]
        ++ desktop_base_modules.home-module.imports;
    };
    
    # Book MacBook Air
    book_air_modules_hyprland = {
    nixos-modules =
      [
        ../hosts/books/air
          {modules.desktop.wayland.enable = true;}
      ]
      ++ desktop_base_modules.nixos-modules;
    home-module.imports =
      [
        ../hosts/books/air/home.nix
          {modules.desktop.hyprland.enable = true;}
      ]
      ++ desktop_base_modules.home-module.imports;
    };
    
    book_air_modules_i3 = {
    nixos-modules =
      [
        ../hosts/books/air
        {modules.desktop.xorg.enable = true;}
      ]
      ++ desktop_base_modules.nixos-modules;
    home-module.imports =
      [
        ../hosts/books/air/home.nix
        {modules.desktop.i3.enable = true;}
      ]
      ++ desktop_base_modules.home-module.imports;
    };

  # darwin systems
  darwin_air_modules = {
    darwin-modules = [
      ../hosts/apples/air
      ../hosts/apples/air/ansi-remapping.nix

      ../modules/darwin
      # ../secrets/darwin.nix
    ];
    home-module.imports = [
      ../hosts/apples/air/home.nix
      ../home/darwin
    ];
  };
  
  darwin_pro_modules = {
    darwin-modules = [
      ../hosts/apples/pro
      ../hosts/apples/pro/iso-remapping.nix

      ../modules/darwin
      ../secrets/darwin.nix
    ];
    home-module.imports = [
      ../hosts/apples/pro/home.nix
      ../home/darwin
    ];
  };
  
  darwin_procs_modules = {
    darwin-modules = [
      ../hosts/apples/procs
      ../hosts/apples/procs/iso-remapping.nix

      ../modules/darwin
      # ../secrets/darwin.nix
    ];
    home-module.imports = [
      ../hosts/apples/procs/home.nix
      ../home/darwin
    ];
  };
}
