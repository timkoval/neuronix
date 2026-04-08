{lib}: {
  username = "tkoval";
  userfullname = "Tim Koval";
  useremail = "timkoval00@gmail.com";

  networking = import ../../vars-networking.nix {inherit lib;};

  hostname = "tk-elitebook";

  initialHashedPassword = "$7$CU..../..../hELzB4HHWG842OCf3Rb01$PfwC0y5b0j2dXBCnDwC9NJt0o.o2WBYjU56k8DbLXVD";

  mainSshAuthorizedKeys = [];
}
