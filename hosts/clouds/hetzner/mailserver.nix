{ config, pkgs, ... }:

{
  # Configure Stalwart Mail Server
  services.stalwart-mail = {
    enable = true;
    openFirewall = true;
    settings = {
      server = {
        hostname = "mail.timkoval.rs";
        tls = {
          enable = true;
          implicit = true;
        };
        listener = {
          smtp = {
            protocol = "smtp";
            bind = "[::]:25";
          };
          submissions = {
            protocol = "smtp";
            bind = "[::]:465";
          };
          imaps = {
            protocol = "imap";
            bind = "[::]:993";
          };
          # jmap = {
          #   protocol = "jmap";
          #   bind = "[::]:8080";
          #   url = "https://mail.timkoval.rs";
          # };
        };
      };

      # ACME configuration for automatic certificate management
      acme."letsencrypt" = {
        # directory = "https://acme-v02.api.letsencrypt.org/directory";
        directory = "https://acme-staging-v02.api.letsencrypt.org/directory";
        challenge = "tls-alpn-01";
        contact = ["timkoval00@gmail.com"];
        domains = ["mail.timkoval.rs" "imap.timkoval.rs" "smtp.timkoval.rs"];
        cache = "%{BASE_PATH}%/etc/acme";
        renew-before = "30d";
      };

      # # Certificate configuration
      # certificate.default = {
      #   cert = "%{BASE_PATH}%/etc/acme/fullchain.pem";
      #   private-key = "%{BASE_PATH}%/etc/acme/key.pem";
      #   default = true;
      # };

      # Authentication configuration
      session.auth = {
        mechanisms = "[plain]";
        directory = "'in-memory'";
      };

      # Storage configuration
      storage.directory = "in-memory";
      session.rcpt.directory = "'in-memory'";
      queue.outbound.next-hop = "'local'";

      # User directory configuration
      directory."in-memory" = {
        type = "memory";
        principals = [
          {
            class = "individual";
            name = "Tim Koval";
            secret = "%{file:${config.age.secrets."iam-email".path}}%";
            email = ["iam@timkoval.rs"];
          }
          {
            class = "individual";
            name = "postmaster";
            secret = "%{file:${config.age.secrets."iam-email".path}}%";
            email = ["postmaster@timkoval.rs"];
          }
        ];
      };

      # Fallback admin configuration
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.age.secrets."iam-email".path}}%";
      };
    };
  };

  # Open necessary ports in the firewall
  networking.firewall.allowedTCPPorts = [ 25 80 443 465 587 993 8080 ];

  # Ensure Stalwart can access ACME certificates
  users.users.stalwart-mail.extraGroups = [ "acme" "users" "keys" ];

  # Optional: Configure Caddy as a reverse proxy for web admin interface
  # services.caddy = {
  #   enable = true;
  #   virtualHosts."webadmin.example.com" = {
  #     extraConfig = ''
  #       reverse_proxy http://127.0.0.1:8080
  #     '';
  #     serverAliases = [
  #       "mta-sts.example.com"
  #       "autoconfig.example.com"
  #       "autodiscover.example.com"
  #       "mail.example.com"
  #     ];
  #   };
  # };
}

