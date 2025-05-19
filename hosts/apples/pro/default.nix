{ hostVariables, ... }:
#############################################################
#
#  Pro - MacBook Pro 14 M3 Pro 18G.
#
#############################################################
{
  networking.hostName = hostVariables.hostname;
  networking.computerName = hostVariables.hostname;
  system.defaults.smb.NetBIOSName = hostVariables.hostname;
}
