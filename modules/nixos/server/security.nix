{hostVars, ...}: {
  # Public Keys that can be used to login to all my servers.
  users.users.${hostVars.username}.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFaX5vplty2Qv9njvMWN0NakhQ8F+lMrZAtr44t69GrceEM20FBRWtC37ZHvsrOhuxo5N/+56wnc5Ly5cSApzgh+R6M+8PAtmeiRrw1eFs+e6fqQk68z7tHeC9Qk73OTcw9Onx++fUw1NF9kkGGi0CDygsRh2Qb1dd+qJSEI/dI9TsB2ERUFyNXI7eTJP3avXFrVtFKU2+naeqsdN8f0VRq301zL8yMV+tEMpdG4zpP1aE5iFCfjcGAFKPD40hy4rfJNYFAtuODKcFI1DRfAyTAKt4lxHg+JVFNXqsoFmfTKlhZqdvRuLQztbedtBFDqQDhWCu11EGHm28CnKn2uRCl75kF6EK06s6x89IsJelRXtBpJ2ZUWDpqvktyUoZkH9VAXWhPV1xMvXjAukh62IpkI0iV8P0lNAm0mDjnsndoevwo+7WZUA08iuF0njtEcKUXPIEYZYR08AjktulCcmIWLjFDNIL1HBWYkbvztywDYjV8NigXTwtz9kf7tqkbU8= tkoval@apple-pro"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB47IwSnwTvU5xxivTqSZ2WVaca0dSg6V8KTqmnkkFaG tkoval@air"
  ];
}
