{ hostVars, ... }:
#############################################################
#
#  Fern - MacBook Pro 2022 13-inch M2 16G, mainly for business.
#
#############################################################
{
  networking.hostName = hostVars.hostname;
  networking.computerName = hostVars.hostname;
  system.defaults.smb.NetBIOSName = hostVars.hostname;
}
