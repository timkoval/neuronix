## ADDED Requirements

### Requirement: Colmena Host Configuration

The system SHALL support Colmena remote deployment for cloud hosts using the new outputs architecture. Each Colmena-enabled host MUST be defined in `outputs/<arch>/src/` and provide:
- `nixosConfigurations.<hostname>` for local builds
- `colmenaMeta.nodeNixpkgs.<hostname>` for per-node nixpkgs
- `colmenaMeta.nodeSpecialArgs.<hostname>` for per-node special arguments
- `colmena.<hostname>` deployment configuration

#### Scenario: Colmena host output generation
- **WHEN** a host file in `outputs/x86_64-linux/src/` exports colmena configuration
- **THEN** the host appears in the merged `colmena` flake output
- **AND** the host can be deployed via `colmena apply --on <hostname>`

### Requirement: Unified colmenaSystem Interface

The `lib/colmenaSystem.nix` helper function SHALL accept the same argument pattern as `lib/nixosSystem.nix` for consistency:
- `inputs`, `lib`, `system`, `genSpecialArgs` - standard flake arguments
- `nixos-modules` - list of NixOS module paths
- `home-modules` - list of Home Manager module paths (optional, defaults to `[]`)
- `hostVars` - host-specific variables attribute set
- `tags` - list of deployment tags for Colmena
- `ssh-user` - SSH user for deployment (optional, defaults to `hostVars.username`)

#### Scenario: Colmena deployment with Home Manager
- **WHEN** `home-modules` is provided with one or more module paths
- **THEN** Home Manager is enabled for the deployment user
- **AND** the modules are imported into the user's Home Manager configuration

#### Scenario: Colmena deployment without Home Manager
- **WHEN** `home-modules` is empty or not provided
- **THEN** Home Manager is not configured for the host
- **AND** the deployment proceeds with NixOS modules only

### Requirement: Host Variables Pattern

Each host MUST define a `variables.nix` file containing host-specific configuration:
- `username` - primary user account name
- `userfullname` - full name for the user
- `useremail` - email address for the user
- `hostname` - the system hostname
- `networking` - networking configuration import

#### Scenario: Host variables are accessible
- **WHEN** a host configuration imports its `variables.nix`
- **THEN** the `hostVars` attribute set is available in all NixOS and Home Manager modules
- **AND** the hostname can be referenced as `hostVars.hostname`
