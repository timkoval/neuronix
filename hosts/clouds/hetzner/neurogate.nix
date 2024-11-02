{ config, pkgs, ... }:

{
  # Enable the service for your Rust application
  systemd.services.neurogate = {
    enable = true;  # Enable the service
    description = "Neurogate - Custom Server Gateway";

    serviceConfig = {
      ExecStart = "/home/tkoval/neurogate/result/bin/neurogate --production";  # Path to your application
      # WorkingDirectory = "/path/to/your/project";  # Adjust this path if needed
      Restart = "always";  # Restart on failure
      StandardOutput = "journal";  # Log output to journal
      StandardError = "journal";  # Log errors to journal
    };

    wantedBy = [ "multi-user.target" ];  # Run in multi-user mode
  };

  # Ensure that your Rust package is available in the system environment
  # environment.systemPackages = [
  #   (pkgs.callPackage /path/to/your/default.nix {})
  # ];
}
