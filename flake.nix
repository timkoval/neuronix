{
  description = "NixOS & macOS configuration of Tim Koval";

  ##################################################################################################################
  #
  # Want to know Nix in details? Looking for a beginner-friendly tutorial?
  # Check out https://github.com/ryan4yin/nixos-and-flakes-book !
  #
  ##################################################################################################################

  # The `outputs` function will return all the build results of the flake.
  # A flake can have many use cases and different types of outputs,
  # parameters in `outputs` are defined in `inputs` and can be referenced by their names.
  # However, `self` is an exception, this special parameter points to the `outputs` itself (self-reference)
  # The `@` syntax here is used to alias the attribute set of the inputs's parameter, making it convenient to use inside the function.
  outputs = inputs @ {
    self,
    nixpkgs,
    pre-commit-hooks,
    ...
  }: let
    constants = import ./constants.nix;

    # `lib.genAttrs [ "foo" "bar" ] (name: "x_" + name)` => `{ foo = "x_foo"; bar = "x_bar"; }`
    forEachSystem = func: (nixpkgs.lib.genAttrs constants.allSystems func);
    allSystemConfigurations = import ./systems {inherit self inputs constants;};
  in
    allSystemConfigurations
    // {
      # format the nix code in this flake
      # alejandra is a nix formatter with a beautiful output
      formatter = forEachSystem (
        system: nixpkgs.legacyPackages.${system}.alejandra
        );

      # pre-commit hooks for nix code
      checks = forEachSystem (
        system: {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              alejandra.enable = true; # formatter
              # deadnix.enable = true; # detect unused variable bindings in `*.nix`
              # statix.enable = true; # lints and suggestions for Nix code(auto suggestions)
              # prettier = {
              #   enable = true;
              #   excludes = [".js" ".md" ".ts"];
              # };
            };
          };
        }
      );
      devShells = forEachSystem (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # fix https://discourse.nixos.org/t/non-interactive-bash-errors-from-flake-nix-mkshell/33310
              bashInteractive
              # fix `cc` replaced by clang, which causes nvim-treesitter compilation error
              gcc
            ];
            name = "dots";
            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}
            '';
          };
        }
      );
    };

  # the nixConfig here only affects the flake itself, not the system configuration!
  # for more information, see:
  #     https://nixos-and-flakes.thiscute.world/nixos-with-flakes/add-custom-cache-servers
  nixConfig = {
    # substituers will be appended to the default substituters when fetching packages
    extra-substituters = [
      # "https://nixpkgs-wayland.cachix.org"
       "https://cache.flox.dev"
    ];
    extra-trusted-public-keys = [
      # "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    ];
  };

  # This is the standard format for flake.nix. `inputs` are the dependencies of the flake,
  # Each item in `inputs` will be passed as a parameter to the `outputs` function after being pulled and built.
  inputs = {
    # There are many ways to reference flake inputs. The most widely used is github:owner/name/reference,
    # which represents the GitHub repository URL + branch/commit-id/tag.

    # Official NixOS package source, using nixos's unstable branch by default
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    # for macos
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # home-manager, used for managing user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      # url = "github:nix-community/home-manager/master";

      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    hyprland = {
      url = "github:hyprwm/Hyprland/v0.39.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # community wayland nixpkgs
    # nixpkgs-wayland.url = "github:nix-community/nixpkgs-wayland";
    # anyrun - a wayland launcher
    anyrun = {
      url = "github:Kirottu/anyrun";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # generate iso/qcow2/docker/... image from nixos configuration
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # secrets management
    agenix = {
      # lock with git commit at 0.14.0
      url = "github:ryantm/agenix/54693c91d923fecb4cf04c4535e3d84f8dec7919";
      # replaced with a type-safe reimplementation to get a better error message and less bugs.
      # url = "github:ryan4yin/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";

    # add git hooks to format nix code before commit
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nuenv.url = "github:DeterminateSystems/nuenv";

    ########################  Some non-flake repositories  #########################################

    # AstroNvim is an aesthetic and feature-rich neovim config.
    astronvim = {
      url = "github:AstroNvim/AstroNvim/v3.41.2";
      flake = false;
    };
    # doom-emacs is a configuration framework for GNU Emacs.
    doomemacs = {
      url = "github:doomemacs/doomemacs";
      flake = false;
    };

    polybar-themes = {
      url = "github:adi1090x/polybar-themes";
      flake = false;
    };

    ########################  My own repositories  #########################################

    # my private secrets, it's a private repository, you need to replace it with your own.
    # use ssh protocol to authenticate via ssh-agent/ssh-key, and shallow clone to save time
    # mysecrets = {
    #   url = "git+ssh://git@github.com/ryan4yin/nix-secrets.git?shallow=1";
    #   flake = false;
    # };

    # my wallpapers
    wallpapers = {
      url = "github:ryan4yin/wallpapers";
      flake = false;
    };
    
    # my neovim config
    neuronvim = {
      url = "github:timkoval/neuronvim";
      flake = false;
    };

    nur-ryan4yin = {
      url = "github:ryan4yin/nur-packages";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # riscv64 SBCs
    nixos-licheepi4a.url = "github:ryan4yin/nixos-licheepi4a";
    # nixos-jh7110.url = "github:ryan4yin/nixos-jh7110";

    # aarch64 SBCs
    nixos-rk3588.url = "github:ryan4yin/nixos-rk3588";
  };
}
