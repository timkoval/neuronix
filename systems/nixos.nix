args:
with args;
with mylib;
with allSystemAttrs; let
  base_args = {
    inherit home-manager nixos-generators;
    inherit nixpkgs; # or nixpkgs-unstable
    system = x64_system;
    specialArgs = allSystemSpecialArgs.x64_system;
  };
in {
  nixosConfigurations = {
    # hp_450 with hyprland compositor
    hp_450_hyprland = nixosSystem (book_hp_450_modules_hyprland // base_args);
 
    # air with hyprland compositor
    air_hyprland = nixosSystem (book_air_modules_hyprland // base_args);
    
    # air with i3wm
    air_i3 = nixosSystem (book_air_modules_i3 // base_args);
    
    # ai with hyprland compositor
    ai_hyprland = nixosSystem (ai_modules_hyprland // base_args);
    # ai with i3 window manager
    # ai_i3 = nixosSystem (idol_ai_modules_i3 // base_args);
  };

  # https://github.com/nix-community/nixos-generators
  packages."${x64_system}" = attrs.mergeAttrsList [
    (
      attrs.listToAttrs
      [
        "hp_450_hyprland"
        "air_hyprland"
        "ai_hyprland"
      ]
      # generate iso image for hosts with desktop environment
      (host: self.nixosConfigurations.${host}.config.formats.iso)
    )
  ];
}
