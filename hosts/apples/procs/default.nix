{hostVars, ...}:
#############################################################
#
#  Procs - MacBook Pro 16 M3 Max 36G.
#
#############################################################
{
  networking.hostName = hostVars.hostname;
  networking.computerName = hostVars.hostname;
  system.defaults.smb.NetBIOSName = hostVars.hostname;

  environment.variables = {
    HERMES_HOME = "/Users/${hostVars.username}/.hermes";
  };

  system.stateVersion = 5; # Did you read the comment?
}
