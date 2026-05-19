# Host-specific variables template
# Copy this file to your host directory as 'variables.nix' and customize it
{
  # User information
  username = "host-user";
  userfullname = "Host User";
  useremail = "host@example.com";

  hostname = "hostname";

  # Security
  # Generate with `mkpasswd -m scrypt` or import from a private file
  initialHashedPassword = "$7$CU..../....EXAMPLE_HASH_HERE";

  # SSH keys - add your authorized keys here
  mainSshAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyHere user@machine"
  ];

  secondaryAuthorizedKeys = [
    # Add any secondary keys here
  ];

  # Theming (optional). All fields default to a Gruvbox Light setup.
  #   scheme    — any file (without .yaml) in
  #               `${pkgs.base16-schemes}/share/themes/`, e.g.
  #               "gruvbox-light-medium", "gruvbox-dark-medium",
  #               "catppuccin-mocha", "nord", "tokyo-night-dark", ...
  #   polarity  — "light" | "dark" | "either"
  #   wallpaper — absolute path to an image (Stylix needs one).
  # stylix = {
  #   scheme = "gruvbox-dark-medium";
  #   polarity = "dark";
  #   wallpaper = "/path/to/image.png";
  # };

  # Add any other host-specific variables needed for your configuration
}
