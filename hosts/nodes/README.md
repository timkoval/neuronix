# Nodes

`hosts/nodes/` contains lightweight Linux hosts such as Raspberry Pi boards,
thin clients, and small edge nodes.

Each host should follow the same structure used in other host groups:

- `default.nix` for system-level host settings
- `variables.nix` for hostVars (username, hostname, SSH keys, password hash)
- `home.nix` for host-specific home-manager overrides
