## Phase 1: Foundation -- Feature Flags and Module Splitting

- [ ] 1.1 Split `modules/nixos/base/misc.nix` into three files:
  - `modules/nixos/base/core.nix` -- nix config, gc, allowUnfree, EDITOR, essential system packages (neovim, curl, git, wget)
  - `modules/nixos/base/packages.nix` -- FHS environment, git-lfs, aria2, psmisc, parted (gated by `neuronix.packages.extended.enable`)
  - `modules/nixos/base/power.nix` -- power-profiles-daemon, upower (gated by `neuronix.power.enable`)
- [ ] 1.2 Add `neuronix.docker.enable` option to `modules/nixos/base/virtualisation.nix`, gate Docker config behind `mkIf`
- [ ] 1.3 Add `neuronix.networking.avahi.enable` option to `modules/nixos/base/networking.nix`, gate Avahi behind `mkIf`
- [ ] 1.4 Add `neuronix.zram.enable` option to `modules/nixos/base/zram.nix` (default true, allows disabling on devices with very low RAM)
- [ ] 1.5 Add `neuronix.btrbk.enable` option to `modules/nixos/base/btrbk.nix` (default false -- only relevant for btrfs hosts)
- [ ] 1.6 Remove old `modules/nixos/base/misc.nix` (replaced by core.nix + packages.nix + power.nix)
- [ ] 1.7 Update `modules/nixos/base/default.nix` to import all refactored modules via scanPaths (should happen automatically if files are in the same directory)
- [ ] 1.8 Verify: `nix eval .#nixosConfigurations.ai-hyprland.config.system.build.toplevel` succeeds
- [ ] 1.9 Verify: `nix eval .#nixosConfigurations.hetzner-tk.config.system.build.toplevel` succeeds

## Phase 2: Profiles

- [ ] 2.1 Create `modules/nixos/profiles/` directory
- [ ] 2.2 Create `modules/nixos/profiles/minimal.nix`:
  - Imports `../base/core.nix`, `../base/networking.nix`, `../base/i18n.nix`, `../../base.nix`
  - Sets: `neuronix.docker.enable = mkDefault false`
  - Sets: `neuronix.power.enable = mkDefault false`
  - Sets: `neuronix.packages.extended.enable = mkDefault false`
  - Sets: `neuronix.networking.avahi.enable = mkDefault false`
  - Sets: `neuronix.btrbk.enable = mkDefault false`
  - Sets: `neuronix.zram.enable = mkDefault true`
  - Sets: `documentation.enable = mkDefault false`
- [ ] 2.3 Create `modules/nixos/profiles/server.nix`:
  - Imports `./minimal.nix`, `../base/virtualisation.nix`, `../base/packages.nix`, `../base/zram.nix`, `../base/btrbk.nix`, `../server/security.nix`
  - Sets: `neuronix.docker.enable = mkDefault true`
  - Sets: `neuronix.packages.extended.enable = mkDefault true`
  - Sets: `documentation.enable = mkDefault true`
- [ ] 2.4 Create `modules/nixos/profiles/desktop.nix`:
  - Imports `./server.nix` and desktop modules
  - Sets: `neuronix.power.enable = mkDefault true`
  - Sets: `neuronix.networking.avahi.enable = mkDefault true`
- [ ] 2.5 Create `modules/nixos/profiles/embedded.nix`:
  - Imports `./minimal.nix`
  - Sets: `environment.noXlibs = true`
  - Sets: `xdg.autostart.enable = false`, `xdg.icons.enable = false`, `xdg.mime.enable = false`, `xdg.sounds.enable = false`
  - Sets: `neuronix.zram.enable = mkDefault true` with `zramSwap.memoryPercent = mkDefault 75`
  - Adds: tmpfs on `/tmp`, conservative gc (3 days)
- [ ] 2.6 Create `modules/nixos/profiles/thin-client.nix`:
  - Imports `./minimal.nix`
  - Enables basic TUI support (foot terminal or similar)
  - Sets: `neuronix.power.enable = mkDefault true` (for battery-powered thin clients)
- [ ] 2.7 Update `modules/nixos/server/server.nix` to import `../profiles/server.nix` instead of raw `../base` + `../../base.nix`
- [ ] 2.8 Update `modules/nixos/desktop.nix` to import `./profiles/desktop.nix` instead of raw `./base` + `../base.nix`
- [ ] 2.9 Verify: existing hosts still evaluate identically (run eval tests)

## Phase 3: Home-Manager Tiering

- [ ] 3.1 Create `home/base/minimal/` directory
- [ ] 3.2 Create `home/base/minimal/default.nix` with essential packages:
  - Packages: neovim, git, curl, ripgrep, fd, fzf, bat, eza, zoxide, jq, tree, file, rsync, gnugrep, gnused
  - Programs: eza (enable, git, icons), bat (enable, config), fzf (enable), zoxide (enable with shell integrations)
- [ ] 3.3 Refactor `home/base/server/core.nix` to import `../minimal` and only declare the *additional* packages (colmena, act, caddy, networking tools, ast-grep, hyperfine, gping, doggo, duf, du-dust, gdu, etc.)
- [ ] 3.4 Create `home/linux/minimal.nix` entry point:
  ```nix
  { imports = [ ../base/minimal ../base/core.nix ./base ]; }
  ```
- [ ] 3.5 Verify: existing hosts' home-manager configs still evaluate identically (darwin + linux)

## Phase 4: aarch64-linux Output Activation

- [ ] 4.1 Create `outputs/aarch64-linux/` directory structure:
  ```
  outputs/aarch64-linux/
  ├── default.nix
  └── src/
  ```
- [ ] 4.2 Create `outputs/aarch64-linux/default.nix` mirroring x86_64-linux pattern (haumea loader, nixosConfigurations, packages, evalTests)
- [ ] 4.3 Uncomment `aarch64-linux` line in `outputs/default.nix` nixosSystems block
- [ ] 4.4 Create a placeholder host in `outputs/aarch64-linux/src/` to validate the output path compiles (can be a minimal QEMU aarch64 config or RPi template)
- [ ] 4.5 Verify: `nix flake show` includes aarch64-linux outputs without errors
- [ ] 4.6 Create `outputs/aarch64-linux/tests/` with at least a hostname eval test

## Phase 5: Host Infrastructure for Nodes

- [ ] 5.1 Create `hosts/nodes/` directory
- [ ] 5.2 Create a template/example node: `hosts/nodes/rpi4-example/`
  - `default.nix` -- imports `modules/nixos/profiles/embedded.nix`, uses `nixos-hardware.raspberryPi4`
  - `variables.nix` -- standard hostVars (username, hostname, SSH keys)
  - `home.nix` -- imports minimal home, enables SSH
- [ ] 5.3 Create corresponding output file: `outputs/aarch64-linux/src/nodes-rpi4-example.nix`
- [ ] 5.4 Verify: the example node evaluates successfully with `nix eval`
- [ ] 5.5 Add the node to Colmena configuration with appropriate tags (e.g., `["embedded" "rpi4"]`)

## Phase 6: Image Pipeline

- [ ] 6.1 Create `images/` directory
- [ ] 6.2 Create `images/sd-card-minimal.nix` -- nixos-generators format definition for minimal aarch64 SD card image
- [ ] 6.3 Create `images/sd-card-server.nix` -- SD card image with server profile
- [ ] 6.4 Wire image generation into flake packages output: `packages.aarch64-linux.sd-rpi4-example`
- [ ] 6.5 Add Justfile recipes:
  - `just build-image <host>` -- build image for a given host
  - `just flash <host> <device>` -- build and flash to SD card/USB
- [ ] 6.6 Verify: at least one image builds (may require cross-compilation or binfmt)

## Phase 7: Verification and Cleanup

- [ ] 7.1 Run `nix flake check` on x86_64-linux (or as much as possible without target hardware)
- [ ] 7.2 Run existing eval tests (hostname, kernel, home-manager) -- all must pass
- [ ] 7.3 Add eval tests for new aarch64-linux hosts (hostname at minimum)
- [ ] 7.4 Update `openspec/project.md` to reflect new architecture:
  - Add profiles/tiers to architecture patterns
  - Add `nodes/` to host naming convention
  - Add `neuronix.*` options to key patterns
  - Add image pipeline to deployment commands
- [ ] 7.5 Update root `README.md` component table with new host categories and profiles
- [ ] 7.6 Run `just fmt` to format all new Nix files with alejandra
- [ ] 7.7 Verify: `nix build` for existing hosts (ai-hyprland, hetzner-tk) produces working configurations
