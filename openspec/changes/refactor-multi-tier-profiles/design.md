## Context

Neuronix needs to support machines ranging from RTX 4090 desktops to Raspberry Pi Zero
devices. The current architecture assumes every NixOS machine needs Docker, power
management, FHS environments, and 60+ CLI tools. Refactoring to a profile/tier system
with feature flags allows the same repo to serve all device classes without duplication.

## Goals / Non-Goals

**Goals:**
- Composable profiles that bundle sensible defaults per device class
- Feature flags (`neuronix.*` options) for individual capabilities
- Profiles set flags via `mkDefault`; hosts can override any flag
- Backward compatibility: existing hosts produce identical closures
- Support for aarch64-linux (RPi, RK3588) and future riscv64-linux
- SD card / raw disk image generation via nixos-generators

**Non-Goals:**
- Yocto integration (deferred; see `PROPOSAL.md` Part 3 for reference design)
- Changing Darwin/macOS configuration
- Changing the haumea-based output system
- Changing the secrets management approach
- Full fleet management (Tailscale mesh, monitoring -- separate proposals)

## Decisions

### Decision 1: Profiles are NixOS modules that set option defaults

Profiles import base modules and set `neuronix.*` options via `lib.mkDefault`.
Hosts import a profile and override specific options as needed.
This is the standard NixOS pattern (similar to `profiles/minimal.nix` in nixpkgs).

**Alternatives considered:**
- Passing a "tier" string and using `if/else` -- rejected: not composable, can't mix tiers
- Separate module trees per tier -- rejected: massive duplication

### Decision 2: Feature flags live under `neuronix.*` namespace

Options like `neuronix.docker.enable`, `neuronix.monitoring.enable`,
`neuronix.power.enable`, etc. are declared co-located with their implementation module.
Each module in `modules/nixos/base/` declares its own `neuronix.*` option and gates
its `config` block behind `lib.mkIf`.

This avoids polluting the upstream `services.*` namespace and keeps option definitions
close to the code they control.

**Alternatives considered:**
- Centralized `options.nix` -- rejected: harder to maintain, options detached from implementation
- Using `modules.*` namespace (current pattern for desktop/secrets) -- rejected: `modules` is too generic and already used inconsistently
- `my.*` or `custom.*` -- rejected: `neuronix.*` matches the project name

### Decision 3: Home-manager minimal tier

- `home/base/minimal/` contains ~15 essential CLI tools (neovim, git, curl, ripgrep, fd,
  fzf, bat, eza, zoxide, jq, tree, file, rsync, gnugrep, gnused)
- `home/base/server/` imports minimal and adds the full toolkit (colmena, act, caddy,
  networking diagnostics, etc.)
- `home/linux/minimal.nix` is the entry point for embedded/thin devices:
  imports `base/minimal`, `base/core.nix`, `linux/base`

### Decision 4: Host category `nodes/` for SBCs and thin clients

`hosts/nodes/` parallels existing categories (`apples`, `boxes`, `books`, `clouds`).
Each node has the standard `default.nix`, `variables.nix`, `home.nix` pattern.

Naming: `nodes/` was chosen over `embedded/`, `things/`, or `devices/` because:
- "nodes" covers both thin clients and SBCs
- Consistent with Colmena/K8s terminology
- Short and neutral

### Decision 5: Image definitions in `images/`

`images/` contains nixos-generators format definitions (SD card, raw disk, ISO).
Output files in `outputs/aarch64-linux/src/` reference these image definitions and
expose them as flake packages: `nix build .#sd-rpi4-dns`.

This keeps image format config separate from host config, allowing the same image
format to be reused across multiple hosts.

## Risks / Trade-offs

- **Risk:** Existing host closures change after refactoring
  - Mitigation: Eval tests already verify hostnames and kernels. Add closure-size
    comparison test. Run `nix build` for existing hosts before and after each phase.

- **Risk:** Feature flag explosion (too many options)
  - Mitigation: Only create options for things that are currently unconditionally enabled
    AND inappropriate for some tier. Start small (~5-6 options), expand as needed.

- **Risk:** Cross-compilation for aarch64 may have nixpkgs cache misses
  - Mitigation: Use `binfmt` (already configured on `ai` box) or native ARM builder.
    Binary cache from Hydra covers most aarch64 packages.

- **Risk:** Profile hierarchy becomes rigid
  - Mitigation: Profiles only use `mkDefault` so any setting is overridable.
    Hosts can import multiple profiles or cherry-pick individual modules.

## Migration Plan

1. All changes are additive first -- new files alongside existing ones
2. Refactor base modules one at a time with feature flags
3. Profiles are new modules that compose existing refactored modules
4. Existing host output files (`boxes-ai.nix`, `clouds-hetzner-tk.nix`) updated last
5. Each step is independently testable: `nix eval`, `nix build`
6. No big-bang rewrite -- each phase can be merged independently

## Open Questions

- Should we add a `neuronix.profile` enum option (e.g., `neuronix.profile = "server"`)
  as syntactic sugar in addition to the individual flags? (Nice for discoverability
  but adds indirection.)
- What's the right threshold for creating a `neuronix.*` option vs leaving something
  unconditionally enabled? (Proposed rule: create an option if the feature adds >5MB
  to the closure or requires a service/daemon.)
- Should `home/base/minimal/` include shell configuration (bash aliases, zoxide, atuin)
  or strictly packages? (Leaning: include zoxide and basic shell setup, exclude atuin
  sync which requires a server.)
