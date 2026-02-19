{hostVars, ...}: {
  networking.hostName = hostVars.hostname;
  users.allowNoPasswordLogin = true;
  system.stateVersion = "24.11";
}
