{ hostVars, ... }:
#############################################################
#
#  Pro - MacBook Pro 14 M3 Pro 18G.
#
#############################################################
{
  networking.hostName = hostVars.hostname;
  networking.computerName = hostVars.hostname;
  system.defaults.smb.NetBIOSName = hostVars.hostname;
  system.stateVersion = 5; # Did you read the comment?
}
