# Host-specific variables for hetzner-tk
{lib}: {
  # User information
  username = "tkoval";
  userfullname = "Tim Koval";
  useremail = "timkoval00@gmail.com";

  networking = import ../../vars-networking.nix {inherit lib;};

  hostname = "hetzner-tk";

  # SSH keys - add your authorized keys here
  mainSshAuthorizedKeys = [
    # TODO: Add your SSH public keys here
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyHere user@machine"
  ];

  initialHashedPassword = "$7$CU..../..../hELzB4HHWG842OCf3Rb01$PfwC0y5b0j2dXBCnDwC9NJt0o.o2WBYjU56k8DbLXVD";
}
