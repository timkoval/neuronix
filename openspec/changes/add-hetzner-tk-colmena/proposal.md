## Why

The `hetzner-tk` cloud host was previously configured using the old flake output structure. After migrating to the new modular `outputs/` architecture with haumea, this host needs to be integrated into the new pattern to enable Colmena remote deployment.

## What Changes

- Rename `hosts/clouds/hetzner/` to `hosts/clouds/hetzner-tk/` for consistency with hostname
- Create `hosts/clouds/hetzner-tk/variables.nix` for host-specific variables (following `boxes/ai/variables.nix` pattern)
- Update `hosts/clouds/hetzner-tk/default.nix` to use `hostVars.hostname` instead of hardcoded value
- Update `lib/colmenaSystem.nix` to support new argument pattern (`home-modules`, `hostVars`, `tags`, `ssh-user`)
- Update `lib/default.nix` `scanPaths` to exclude `variables.nix` files from module scanning
- Update `outputs/x86_64-linux/src/clouds-hetzner-tk.nix` to include `hostVars` in `nodeSpecialArgs`
- Create `outputs/x86_64-linux/src/clouds-hetzner-tk.nix` output definition
- Update `hosts/README.md` to document cloud hosts
- Fix `hosts/vars-networking.nix` syntax error (pre-existing bug)
- Comment out `openspec` in server home-manager config (requires network access during build)

## Impact

- Affected specs: colmena-deployment (new capability)
- Affected code:
  - `hosts/clouds/hetzner/` -> `hosts/clouds/hetzner-tk/`
  - `lib/colmenaSystem.nix`
  - `lib/default.nix`
  - `hosts/vars-networking.nix`
  - `home/base/server/core.nix`
  - `outputs/x86_64-linux/src/clouds-hetzner-tk.nix` (new)
  - `hosts/README.md`


