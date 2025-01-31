{ config, pkgs, nixos-mailserver,... }:

{
  imports = [
    nixos-mailserver.nixosModule
  ];

  mailserver = {
    enable = true;
    fqdn = "mail.timkoval.rs";
    domains = [ "timkoval.rs" ];

    loginAccounts = {
      "iam@timkoval.rs" = {
        hashedPasswordFile = "/etc/agenix/iam-email";
      };
    };

    certificateScheme = "acme-nginx";
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "timkoval00@gmail.com";
}
