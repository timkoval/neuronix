## Why

The current module architecture has a binary split (server vs desktop) with a "base"
layer that's too heavy for embedded/thin devices. Modules like Docker, FHS environment,
power-profiles-daemon, and git-lfs are unconditionally included for all NixOS hosts.
Similarly, home-manager's "server" tier installs ~60 CLI packages that are excessive for
a Raspberry Pi running DNS. This prevents the repo from scaling to thin clients, IoT
devices, and minimal appliances without duplicating significant configuration.

## What Changes

- **BREAKING**: `modules/nixos/base/misc.nix` split into `core.nix` + `packages.nix` + `power.nix`
- Introduce `neuronix.*` NixOS options with `mkEnableOption` for conditional features
- Add `modules/nixos/profiles/` with composable profiles: `minimal`, `server`, `desktop`, `embedded`, `thin-client`
- Split `home/base/server/core.nix` into `home/base/minimal/` + `home/base/server/`
- Add `home/linux/minimal.nix` entry point
- Activate `outputs/aarch64-linux/` in flake outputs
- Add `hosts/nodes/` category for SBCs and thin clients
- Add `images/` directory for `nixos-generators` image definitions
- Add Justfile recipes for new deployment targets
- Update `modules/nixos/server/server.nix` to use profiles

## Impact

- Affected code: `modules/nixos/base/*`, `modules/nixos/server/`, `home/base/server/`, `home/linux/`, `outputs/default.nix`, `Justfile`
- Existing hosts (`ai-hyprland`, `hetzner-tk`, macOS) MUST continue to work identically
- No changes to secrets, overlays, or darwin modules
