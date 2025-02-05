_:
#############################################################
#
#  Pro - MacBook Pro 14 M3 Pro 18G.
#
#############################################################
let
  hostname = "Timurs-MacBook-Pro";
in {
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
  system.stateVersion = 5; # Did you read the comment?
}
