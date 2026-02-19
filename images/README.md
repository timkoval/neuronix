# Images

This directory contains reusable image-oriented NixOS modules.

- `sd-card-minimal.nix`: baseline tweaks for minimal ARM SD card images
- `sd-card-server.nix`: server-oriented SD card image defaults

Image derivations are exposed through flake packages under
`packages.<system>.<name>` and can be built with `nix build`.
