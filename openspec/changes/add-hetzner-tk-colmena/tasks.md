## 1. Directory Restructure

- [x] 1.1 Rename `hosts/clouds/hetzner/` to `hosts/clouds/hetzner-tk/`
- [x] 1.2 Create `hosts/clouds/hetzner-tk/variables.nix` with user configuration

## 2. Host Configuration Updates

- [x] 2.1 Update `hosts/clouds/hetzner-tk/default.nix` to use `hostVars.hostname`

## 3. Library Updates

- [x] 3.1 Update `lib/colmenaSystem.nix` to support new argument pattern:
  - Change `home-module` to `home-modules` (list)
  - Change `host_tags` to `tags`
  - Add `hostVars` parameter
  - Add `ssh-user` parameter
- [x] 3.2 Update `lib/default.nix` `scanPaths` to exclude `variables.nix`
- [x] 3.3 Update `outputs/x86_64-linux/src/clouds-hetzner-tk.nix` to include `hostVars` in `nodeSpecialArgs`

## 4. Output Definition

- [x] 4.1 Create `outputs/x86_64-linux/src/clouds-hetzner-tk.nix`

## 5. Documentation

- [x] 5.1 Update `hosts/README.md` to include cloud hosts section

## 6. Bug Fixes and Adjustments (discovered during implementation)

- [x] 6.1 Fix `hosts/vars-networking.nix` syntax error (missing value for `knownHosts`)
- [x] 6.2 Comment out `openspec` package in `home/base/server/core.nix` (requires network during build)
- [x] 6.3 Add `mainSshAuthorizedKeys` to `hosts/clouds/hetzner-tk/variables.nix`

## 7. Verification

- [x] 7.1 Verify `nixosConfigurations.hetzner-tk` exists and hostname is correct
- [x] 7.2 Verify `colmena.hetzner-tk` deployment config is correct

