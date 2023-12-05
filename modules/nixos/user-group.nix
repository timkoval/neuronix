{ username, ... }: 

{
  nix.settings.trusted-users = [username];

  # Don't allow mutation of users outside the config.
  users.mutableUsers = false;

  users.groups = {
    "${username}" = {};
    docker = {};
    wireshark = {};
    # for android platform tools's udev rules
    adbusers ={};
    dialout = {};
    # for openocd (embedded system development)
    plugdev = {};
    # misc
    uinput = {};
  };

  users.users."${username}" = {
    # generated by `mkpasswd -m scrypt`
    # we have to use initialHashedPassword here when using tmpfs for /
    initialHashedPassword = "$7$CU..../....Sdl/JRH..9eIvZ6mE/52r.$xeR6lyvTcVVKt28Owcoc/vPOOECcYSiq1xjw/QCz2t0";
    home = "/home/${username}";
    isNormalUser = true;
    description = username;
    extraGroups = [
      username
      "users"
      "networkmanager"
      "wheel"
      "docker"
      "wireshark"
      "adbusers"
      "libvirtd"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDiipi59EnVbi6bK1bGrcbfEM263wgdNfbrt6VBC1rHx ryan@ai-idols"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7PTkP3ixXTZlrJNSHnXgkmHNT+QslFi9wNYXOpVwGB ryan@harmonica"
    ];
  };
  users.users.root.initialHashedPassword = "$7$CU..../....X6uvZYnFD.i1CqqFFNl4./$4vgqzIPyw5XBr0aCDFbY/UIRRJr7h5SMGoQ/ZvX3FP2";

  # DO NOT promote the specified user to input password for `nix-store` and `nix-copy-closure`
  security.sudo.extraRules = [
    {
      users = [username];
      commands = [
        {
          command = "/run/current-system/sw/bin/nix-store";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/nix-copy-closure";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
