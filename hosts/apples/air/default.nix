{ hostVariables, ... }:
#############################################################
#
#  Fern - MacBook Pro 2022 13-inch M2 16G, mainly for business.
#
#############################################################
{
  networking.hostName = hostVariables.hostname;
  networking.computerName = hostVariables.hostname;
  system.defaults.smb.NetBIOSName = hostVariables.hostname;
}
