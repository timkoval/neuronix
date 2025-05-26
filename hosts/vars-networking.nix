{lib}: rec {
  defaultGateway = "192.168.5.201";
  nameservers = [
    "119.29.29.29" # DNSPod
    "223.5.5.5" # AliDNS
    "1.1.1.1" # Cloudflare
  ];
  prefixLength = 24;

  hostAddress = {
    "ai" = {
      inherit prefixLength;
      address = "192.168.5.100";
    };
    "hetzner-tk" = {
      inherit prefixLength;
      address = "5.75.140.70";
    };
  };

  ssh = {
    # define the host alias for remote builders
    # this config will be written to /etc/ssh/ssh_config
    # ''
    #   Host ruby
    #     HostName 192.168.5.102
    #     Port 22
    #
    #   Host kana
    #     HostName 192.168.5.103
    #     Port 22
    #   ...
    # '';
    extraConfig =
      lib.attrsets.foldlAttrs
      (acc: host: value:
        acc
        + ''
          Host ${host}
            HostName ${value.address}
            Port 22
        '')
      ""
      hostAddress;

    # define the host key for remote builders so that nix can verify all the remote builders
    # this config will be written to /etc/ssh/ssh_known_hosts
    knownHosts =
      # Update only the values of the given attribute set.
      #
      #   mapAttrs
      #   (name: value: ("bar-" + value))
      #   { x = "a"; y = "b"; }
      #     => { x = "bar-a"; y = "bar-b"; }
      # lib.attrsets.mapAttrs
      # (host: value: {
      #   hostNames = [host hostAddress.${host}.address];
      #   publicKey = value.publicKey;
      # })
      # {
      #   aquamarine.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO0EzzjnuHBE9xEOZupLmaAj9xbYxkUDeLbMqFZ7YPjU";
      # };
  };
}
