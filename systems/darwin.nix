args:
with args;
with mylib;
with allSystemAttrs; let
  base_args = {
    inherit nix-darwin home-manager;
    nixpkgs = nixpkgs-darwin;
  };
in {
  # macOS's configuration
  darwinConfigurations = {
    # harmonica = macosSystem (
    #   attrs.mergeAttrsList [
    #     base_args
    #     darwin_harmonica_modules
    #     {
    #       system = allSystemAttrs.x64_darwin;
    #       specialArgs = allSystemSpecialArgs.x64_darwin;
    #     }
    #   ]
    # );

    air = macosSystem (
      attrs.mergeAttrsList [
        base_args
        darwin_air_modules
        {
          system = aarch64_darwin;
          specialArgs = allSystemSpecialArgs.aarch64_darwin;
        }
      ]
    );
    
    pro = macosSystem (
      attrs.mergeAttrsList [
        base_args
        darwin_pro_modules
        {
          system = aarch64_darwin;
          specialArgs = allSystemSpecialArgs.aarch64_darwin;
        }
      ]
    );
    
    procs = macosSystem (
      attrs.mergeAttrsList [
        base_args
        darwin_procs_modules
        {
          system = aarch64_darwin;
          specialArgs = allSystemSpecialArgs.aarch64_darwin // {username="timur"; userfullname="Tim"; useremail="timkoval00@gmail.com";};
        }
      ]
    );
  };
}
