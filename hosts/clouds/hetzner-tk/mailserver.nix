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

    certificateScheme = "acme";
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "mail+timkoval00@gmail.com";
  security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
  security.acme.certs."mail.timkoval.rs" = {
    webroot = "/var/lib/acme/acme-challenge";
    email = "mail+timkoval00@gmail.com";
    group = "users";
  };
  users.users.tkoval.extraGroups = [ "acme" ];
}
