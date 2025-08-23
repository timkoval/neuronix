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
  # initialHashedPassword = "$7$CU..../....EXAMPLE_HASH_HERE";
  
  # SSH keys - add your authorized keys here
  # mainSshAuthorizedKeys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyHere user@machine"
  # ];
  
  # secondaryAuthorizedKeys = [
  #   # Add any secondary keys here
  # ];
  
  # Add any other host-specific variables needed for your configuration
}
