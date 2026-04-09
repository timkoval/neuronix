{lib}: {
  username = "tkoval";
  userfullname = "Tim Koval";
  useremail = "timkoval00@gmail.com";

  networking = import ../../vars-networking.nix {inherit lib;};

  hostname = "tk-elitebook";

  initialHashedPassword = "$y$j9T$WIHgmW9kWHpdWlzfE0FxE.$P80ipWW4AP1IXPXioOQrIerrvHGXST3wipdThnQ/7p9";

  mainSshAuthorizedKeys = [];
}
