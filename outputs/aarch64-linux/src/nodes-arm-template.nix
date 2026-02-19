{
  inputs,
  lib,
  mylib,
  system,
  genSpecialArgs,
  ...
} @ args: let
  name = "arm-template";
  hostVars = {
    username = "arm";
    userfullname = "ARM Template";
    useremail = "arm@example.local";
    hostname = name;
    initialHashedPassword = "!";
    mainSshAuthorizedKeys = [];
  };

  modules = {
    nixos-modules =
      map mylib.relativeToRoot [
        "modules/nixos/server/server.nix"
      ]
      ++ [
        {
          networking.hostName = hostVars.hostname;
          system.stateVersion = "24.11";
        }
      ];
    home-modules = map mylib.relativeToRoot [
      "home/linux/server.nix"
    ];
  };

  systemArgs = modules // args // {inherit hostVars;};
in {
  nixosConfigurations.${name} = mylib.nixosSystem systemArgs;

  colmenaMeta = {
    nodeNixpkgs.${name} = import inputs.nixpkgs {inherit system;};
    nodeSpecialArgs.${name} = (genSpecialArgs system) // {inherit hostVars;};
  };

  colmena.${name} = mylib.colmenaSystem (systemArgs // {tags = ["arm" "template"];});
}
