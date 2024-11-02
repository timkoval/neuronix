args:
with args;
with mylib;
with allSystemAttrs; let
  # x86_64 related
  x64_base_args = {
    inherit home-manager;
    inherit nixpkgs; # or nixpkgs-unstable
    specialArgs = allSystemSpecialArgs.x64_system // {username="tkoval"; userfullname="Tim Koval"; useremail="timkoval00@gmail.com";};
  };

in {
  # colmena - remote deployment via SSH
  colmena = {
    meta = {
      nixpkgs = import nixpkgs {system = x64_system;};
      specialArgs = allSystemSpecialArgs.x64_system // {username="tkoval"; userfullname="Tim Koval"; useremail="timkoval00@gmail.com";};
    };

    hetzner-tk = colmenaSystem (attrs.mergeAttrsList [
      x64_base_args
      cloud_hetzner_tk_modules
      {host_tags = cloud_hetzner_tk_tags;}
    ]);
  };
}
