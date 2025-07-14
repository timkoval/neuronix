{hostVars, ...}: {
  # Public Keys that can be used to login to all my servers.
  users.users.${hostVars.username}.openssh.authorizedKeys.keys = hostVars.mainSshAuthorizedKeys;
}
