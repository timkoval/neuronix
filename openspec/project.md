# Project Context

## Purpose
A comprehensive NixOS & macOS (nix-darwin) configuration flake that manages Tim Koval's personal and work machines. The goal is reproducible, declarative system configurations across multiple hosts including:
- macOS laptops (MacBook Air M1, MacBook Pro M3, MacBook Pro Intel)
- NixOS desktops (gaming/daily-use workstation with Ryzen 5600X + RTX 3050)
- NixOS laptops (MacBook Air with Asahi Linux, HP ProBook)
- Cloud servers (Hetzner)

## Tech Stack
- **Nix/NixOS**: Core declarative configuration language and OS (version 24.11)
- **Nix Flakes**: Modern Nix dependency management and reproducible builds
- **Home Manager**: User environment management (release-24.11)
- **nix-darwin**: macOS system configuration
- **Colmena**: Remote deployment tool for NixOS systems
- **agenix**: Secrets management via age encryption
- **Just**: Command runner (with Nushell scripting)
- **Nushell**: Shell used for automation scripts

### Desktop Environment Components
| Component | Wayland (Hyprland) | Xorg (i3) |
|-----------|-------------------|-----------|
| Window Manager | Hyprland | i3 |
| Terminal | Zellij + Kitty | Zellij + Kitty |
| Bar | Waybar | Polybar |
| Launcher | anyrun | rofi |
| Notifications | Mako | Dunst |
| Display Manager | GDM | GDM |
| Color Scheme | Catppuccin | Catppuccin |

### Editors
- Neovim (neuronvim config)
- Doom Emacs

## Project Conventions

### Code Style
- Use `nix fmt` for formatting Nix files
- Pre-commit hooks configured via `pre-commit-hooks.nix`
- Nix expressions should be modular and composable
- Use descriptive attribute names in kebab-case for file names, camelCase for Nix attributes

### Architecture Patterns

#### Directory Structure
```
neuronix/
├── flake.nix          # Entry point, inputs only - outputs delegated to ./outputs
├── outputs/           # Flake outputs organized by architecture
│   ├── aarch64-darwin/  # macOS ARM configurations
│   └── x86_64-linux/    # Linux x86_64 configurations
├── hosts/             # Machine-specific configurations
│   ├── apples/        # macOS machines
│   ├── books/         # Linux laptops
│   ├── boxes/         # Linux desktops
│   └── clouds/        # Cloud/server machines
├── home/              # Home Manager modules
│   ├── base/          # Cross-platform (Linux & macOS)
│   ├── darwin/        # macOS-specific
│   └── linux/         # Linux-specific
├── modules/           # NixOS/nix-darwin system modules
│   ├── nixos/         # NixOS modules
│   ├── darwin/        # nix-darwin modules
│   └── base.nix       # Common to both
├── lib/               # Helper functions for reducing boilerplate
├── secrets/           # agenix secret declarations
└── overlays/          # Nixpkgs overlays
```

#### Key Patterns
1. **Layered Configuration**: base -> os-specific -> host-specific
2. **Helper Functions**: `lib/` contains `nixosSystem.nix`, `macosSystem.nix`, `colmenaSystem.nix` to reduce duplication
3. **Separation of Concerns**: System config (`modules/`) vs user config (`home/`)
4. **Private Secrets Repository**: Secrets stored in separate `nix-secrets` repo, referenced as flake input

### Testing Strategy
- GitHub Actions workflow for `nix flake check` on push/PR
- NixOS tests in `outputs/*/tests/` directories
- Manual testing via `just` commands before deployment

### Git Workflow
- Main branch for stable configurations
- Pre-commit hooks for Nix formatting
- Secrets managed in separate private repository (`timkoval/nix-secrets`)

## Domain Context

### Host Naming Convention
- **apples/**: macOS Darwin machines (air, pro, procs)
- **books/**: Linux laptops
- **boxes/**: Linux desktops (ai = main workstation)
- **clouds/**: Cloud/server deployments (hetzner)

### Deployment Commands
```bash
# NixOS
just i3           # Deploy with i3 window manager
just hypr         # Deploy with Hyprland compositor

# macOS
just air          # MacBook Air M1
just pro          # MacBook Pro M3
just procs        # MacBook Pro Intel (work)

# Maintenance
just up           # Update all flake inputs
just upp <input>  # Update specific input
just fmt          # Format Nix files
just gc           # Garbage collect Nix store
```

### Secrets Flow
1. Secrets encrypted with host public keys via agenix
2. Stored in private `nix-secrets` repository
3. Decrypted at deployment time using host's `/etc/ssh/ssh_host_ed25519_key`
4. Never stored unencrypted in Nix store

## Important Constraints
- **Hardware-Specific**: Configurations contain machine-specific hardware settings (not portable)
- **Private Secrets**: `mysecrets` input requires access to private repository
- **Secure Boot**: Some hosts use lanzaboote for secure boot
- **Encryption**: Desktop systems use tmpfs on `/` with Btrfs on LUKS for persistence
- **Impermanence**: Some hosts configured with impermanence pattern

## External Dependencies

### Flake Inputs
- **nixpkgs**: NixOS 24.11 (stable), unstable, and darwin variants
- **home-manager**: release-24.11
- **nix-darwin**: nix-darwin-24.11
- **nixos-hardware**: Hardware-specific configurations
- **lanzaboote**: Secure boot support
- **ghostty**: Terminal emulator
- **agenix**: Secrets management
- **disko**: Declarative disk partitioning
- **nixos-generators**: Image generation (ISO, QCOW2, etc.)
- **nixpak**: Application sandboxing
- **nixos-mailserver**: Email server configuration

### Personal Repositories
- `timkoval/nix-secrets`: Private secrets repository
- `timkoval/neuronvim`: Neovim configuration
- `timkoval/nur-packages`: Personal Nix User Repository packages
- `ryan4yin/wallpapers`: Wallpaper collection
