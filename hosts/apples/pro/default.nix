_:
#############################################################
#
#  Pro - MacBook Pro 14 M3 Pro 18G.
#
#############################################################
let
  hostname = "apple-pro";
in {
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
}
