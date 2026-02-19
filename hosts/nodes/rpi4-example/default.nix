{hostVars, ...}: {
  networking.hostName = hostVars.hostname;
  system.stateVersion = "24.11";
}
