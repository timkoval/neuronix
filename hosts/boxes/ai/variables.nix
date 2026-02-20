# Host-specific variables template
# Copy this file to your host directory as 'variables.nix' and customize it
{lib}: {
  # User information
  username = "tkoval";
  userfullname = "Tim Koval";
  useremail = "timkoval00@gmail.com";

  networking = import ../../vars-networking.nix {inherit lib;};

  hostname = "hostname";

  # Security
  # Generate with `mkpasswd -m scrypt` or import from a private file
  initialHashedPassword = "$7$CU..../..../hELzB4HHWG842OCf3Rb01$PfwC0y5b0j2dXBCnDwC9NJt0o.o2WBYjU56k8DbLXVD";

  # SSH keys - add your authorized keys here
  mainSshAuthorizedKeys = [];

  # secondaryAuthorizedKeys = [
  #   # Add any secondary keys here
  # ];

  # Add any other host-specific variables needed for your configuration
}
