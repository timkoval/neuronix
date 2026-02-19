# Neuronix Architecture Proposal: Multi-Tier Device Support

## Context

Neuronix currently manages macOS laptops, NixOS desktops, and a single Hetzner cloud
server. The goal is to extend the same repository to cover the full spectrum of machines:

| Tier | Examples | Characteristics |
|------|----------|-----------------|
| **Desktop** | RTX 4090 workstation, MacBooks | Full GUI, editors, dev tools, gaming |
| **Server** | Hetzner VPS, home NAS, dedicated | Headless, Docker, monitoring, services |
| **Thin client** | Intel NUC, old laptop | Minimal GUI or TUI-only, remote access |
| **Embedded/IoT** | Raspberry Pi, RK3588, RISC-V | Minimal footprint, single-purpose, constrained resources |
| **Appliance** | Sensor gateway, kiosk | Ultra-minimal, possibly read-only root, fast boot |

This document analyzes available approaches and recommends an architecture.

---

## Part 1: Embedded/Minimal Image Options

### Option A: NixOS Minimal (Recommended starting point)

**What:** Use standard NixOS with aggressive pruning: `noXlibs`, disabled docs, minimal
kernel, custom module imports.

**Image size:** 200-500MB depending on services
**Boot time:** 5-15s (systemd)

**Pros:**
- Same tooling, same repo, same deployment pipeline (Colmena/deploy-rs)
- Full Nix store at runtime -- can update declaratively
- `nixos-generators` produces SD card images, raw disks, ISOs, QCOW2
- Cross-compilation from x86 via `pkgsCross.aarch64-multiplatform`
- `nixos-hardware` has RPi 3/4/5 modules

**Cons:**
- Can't go below ~150MB (glibc + nix store overhead)
- Boot time floor of ~5s with systemd
- Not suitable if vendor only provides Yocto BSP layers

**Verdict:** Covers 90% of use cases. Start here.

### Option B: NixOS + Container Architecture

**What:** Run ultra-minimal NixOS host (just container runtime + SSH + mesh VPN).
Application logic runs in OCI containers built by Nix
(`pkgs.dockerTools.buildLayeredImage`).

**Image size:** Host ~200MB + containers as needed
**Boot time:** 5-10s

**Pros:**
- Host OS stays tiny and stable; apps are independently deployable
- Containers are built reproducibly by Nix in the same flake
- Natural fit for K3s worker nodes
- Can mix Nix-built containers with third-party images

**Cons:**
- Container overhead (memory, cgroup management)
- Two layers of abstraction (NixOS host + container)
- Not great for direct hardware access (GPIO, SPI, I2C)

**Verdict:** Excellent for K3s nodes, media servers, multi-service gateways.

### Option C: `not-os`

**What:** A minimal NixOS-like system without systemd. Uses runit or simple init.
Still leverages nixpkgs and Nix module system.

- Repository: https://github.com/cleverca22/not-os

**Image size:** 50-80MB
**Boot time:** 2-5s

**Pros:**
- Stays in Nix ecosystem, uses nixpkgs derivations
- Much smaller than full NixOS
- No systemd overhead

**Cons:**
- Unmaintained / community project (low bus factor)
- No systemd means no journald, no networkd, no timers
- Missing many NixOS modules that assume systemd
- Significant DIY effort for service management

**Verdict:** Interesting research target. Not production-ready. Evaluate only if NixOS
minimal demonstrably can't meet size requirements on your hardware.

### Option D: Buildroot

**What:** Makefile + Kconfig-based embedded Linux build system. Produces minimal
rootfs images.

- Website: https://buildroot.org/

**Image size:** 5-30MB
**Boot time:** 1-3s

**Pros:**
- Simpler than Yocto (no layer system, no BitBake)
- Produces truly minimal images (busybox + your app)
- Good for single-purpose appliances

**Cons:**
- Completely separate toolchain from Nix
- No package manager at runtime
- No declarative configuration
- Fewer vendor BSPs than Yocto
- Must maintain two build systems

**Verdict:** Better than Yocto for simple appliances if Nix can't meet size/boot
constraints. Still a separate world from your Nix config.

### Option E: Yocto / OpenEmbedded

**What:** Industrial-grade embedded Linux build framework. Layer-based architecture
with BitBake build engine.

- Website: https://www.yoctoproject.org/

**Image size:** 5-50MB
**Boot time:** 1-3s

**Pros:**
- Industry standard for commercial embedded products
- Massive vendor BSP ecosystem (most SoC vendors provide Yocto layers)
- License compliance tooling (license manifests, SPDX, CVE tracking)
- Robust OTA update integration (SWUpdate, RAUC, Mender)
- A/B partition schemes, dm-verity, secure boot chains
- Proven in production for millions of shipped devices

**Cons:**
- Steep learning curve (BitBake, layers, recipes, bbappend)
- Long build times (hours for first build, even with sstate-cache)
- Completely different paradigm from Nix
- Maintaining both Nix and Yocto in one repo adds significant complexity
- No runtime package manager (baked images, like Buildroot)

**Hybrid approach -- Nix wrapping Yocto:**
- Create a Nix derivation that runs BitBake inside a Nix sandbox
- `nix build .#yocto-sensor-gateway` produces a flashable image
- Yocto sstate-cache can be stored in a Nix-managed binary cache
- Share host variables (IPs, SSH keys, hostnames) between Nix and Yocto via JSON
  export from `hosts/*/variables.nix`

**Verdict:** Only justified for commercial products requiring vendor BSP, license
compliance, or sub-50MB images. Defer until a concrete device demands it.

### Option F: NixOS `modulesPath` Pruning

**What:** Instead of importing all NixOS modules, selectively import only what you need.

```nix
{ modulesPath, ... }: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
    (modulesPath + "/services/networking/ssh/sshd.nix")
    # Only what you actually use
  ];
  documentation.enable = false;
  fonts.fontconfig.enable = false;
  environment.noXlibs = true;
  xdg.autostart.enable = false;
  xdg.icons.enable = false;
  xdg.mime.enable = false;
  xdg.sounds.enable = false;
}
```

**Image size:** 150-300MB

**Pros:** No new tools, stays 100% NixOS

**Cons:** Fragile -- NixOS modules have implicit dependencies that can break when you
prune aggressively

**Verdict:** Use as a complement to Option A, not standalone.

---

## Part 2: Recommendation Matrix

| Device Category | Recommended Approach | Fallback |
|-----------------|---------------------|----------|
| Raspberry Pi (homelab) | NixOS Minimal (A) | -- |
| K3s worker nodes | NixOS + Containers (B) | NixOS Minimal (A) |
| Home NAS / media server | NixOS Minimal (A) | -- |
| Thin client with TUI | NixOS Minimal (A) + profiles | -- |
| Network appliance (DNS, VPN) | NixOS Minimal (A) | -- |
| Home automation gateway | NixOS Minimal (A) | Buildroot (D) if <50MB needed |
| Sensor gateway (commercial) | Yocto (E) | NixOS Minimal (A) for prototype |
| Kiosk / single-app display | NixOS Minimal (A) + cage | -- |
| Custom SoC with vendor BSP only | Yocto (E) | -- |

---

## Part 3: Yocto Integration Architecture (Future Reference)

If/when Yocto is needed, here's how it would fit in the repo:

```
neuronix/
├── yocto/                           # Yocto workspace (gitignored build artifacts)
│   ├── layers/
│   │   ├── meta-neuronix/           # Custom Yocto layer
│   │   │   ├── conf/layer.conf
│   │   │   ├── recipes-core/
│   │   │   │   └── images/
│   │   │   │       ├── neuronix-minimal-image.bb
│   │   │   │       └── neuronix-gateway-image.bb
│   │   │   └── recipes-app/
│   │   │       └── neurogate/
│   │   │           └── neurogate_git.bb
│   │   └── meta-vendor-bsp/         # Vendor BSP (submodule or fetched)
│   ├── build/                       # BitBake build dir (gitignored)
│   └── conf/
│       ├── local.conf
│       └── bblayers.conf
├── yocto.nix                        # Nix derivation that invokes BitBake
└── hosts/appliances/                # Device configs shared between Nix and Yocto
    └── sensor-gateway/
        ├── variables.nix            # Shared variables (exported as JSON for Yocto)
        └── yocto-config.json        # Generated from variables.nix
```

Key integration points:
1. `nix build .#yocto-sensor-gateway` invokes BitBake in a sandboxed environment
2. `hosts/appliances/*/variables.nix` is the single source of truth for device identity
3. A helper script exports `variables.nix` -> JSON -> Yocto `local.conf` overrides
4. Yocto sstate-cache stored in S3/Cachix for CI reproducibility

This is **not** implemented now -- it's a reference design for when the need arises.

---

## Part 4: Elevating the Existing Config

Beyond embedded support, these improvements are recommended (separate from the
multi-tier refactoring):

### Fleet Management
- **deploy-rs** or **enhanced Colmena with tags** -- deploy to groups:
  `colmena apply --on @embedded`, `--on @cloud`
- **Tailscale/WireGuard mesh** as a base module -- every device gets a stable mesh IP
- **Monitoring** -- `prometheus-node-exporter` on all nodes, Grafana on a server

### Reliability
- **Impermanence** -- tmpfs root with explicit persist declarations
  (already a flake input, not yet active)
- **Disko everywhere** -- declarative disk layout for all hosts, not just Hetzner
- **NixOS tests** -- expand VM-based integration tests for infrastructure scenarios

### Image Pipeline
- **`nixos-generators`** -- `nix build .#sd-rpi4-dns` produces flashable SD card image
- **Cross-compilation** -- build aarch64 images on x86 workstation
  (binfmt already configured on the `ai` box)

---

## Part 5: Implementation Plan

See `openspec/changes/refactor-multi-tier-profiles/tasks.md` for the detailed
implementation checklist covering the Nix refactoring work.

Summary of phases:

1. **Foundation** -- Split base modules, add `mkEnableOption` feature flags
2. **Profiles** -- Create composable profiles (minimal, server, desktop, embedded, thin-client)
3. **Home-Manager Tiering** -- Extract minimal package set, create `home/linux/minimal.nix`
4. **aarch64-linux Activation** -- Create output directory, enable in flake outputs
5. **Node Hosts** -- Add `hosts/nodes/` category with example RPi config
6. **Image Pipeline** -- `nixos-generators` integration, Justfile recipes
7. **Verification** -- Eval tests, formatting, documentation updates
