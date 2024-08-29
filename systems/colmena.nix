args:
with args;
with mylib;
with allSystemAttrs; let
  # x86_64 related
  x64_base_args = {
    inherit home-manager;
    inherit nixpkgs; # or nixpkgs-unstable
    specialArgs = allSystemSpecialArgs.x64_system;
  };

in {
  # colmena - remote deployment via SSH
  colmena = {
    meta = {
      nixpkgs = import nixpkgs {system = x64_system;};
      specialArgs = allSystemSpecialArgs.x64_system;
    };
  };
}
