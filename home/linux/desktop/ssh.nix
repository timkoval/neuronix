{pkgs, ...}: {
  programs.ssh = {
    enable = true;

    # all my ssh private key are generated by `ssh-keygen -t ed25519 -C "ryan@nickname"`
    # the config's format:
    #   Host —  given the pattern used to match against the host name given on the command line.
    #   HostName — specify nickname or abbreviation for host
    #   IdentityFile — the location of your SSH key authentication file for the account.
    # format in details:
    #   https://www.ssh.com/academy/ssh/config
    extraConfig = ''
      # a private key that is used during authentication will be added to ssh-agent if it is running
      AddKeysToAgent yes

      Host 192.168.*
        # allow to securely use local SSH agent to authenticate on the remote machine.
        # It has the same effect as adding cli option `ssh -A user@host`
        ForwardAgent yes
        # romantic holds my homelab~
        IdentityFile ~/.ssh/romantic
        # Specifies that ssh should only use the identity file explicitly configured above
        # required to prevent sending default identity files first.
        IdentitiesOnly yes

      Host github.com
          # github is controlled by gluttony~
          IdentityFile ~/.ssh/gh_rsa
          # Specifies that ssh should only use the identity file explicitly configured above
          # required to prevent sending default identity files first.
          IdentitiesOnly yes

      Host gitlab.com
          IdentityFile ~/.ssh/gl_rsa
          IdentitiesOnly yes

      Host git.ftc.ru
          IdentityFile ~/.ssh/qp_rsa
          IdentitiesOnly yes

      Host dt
          HostName 100.116.246.152
          User tkoval
          IdentityFile ~/.ssh/dt_rsa
          IdentitiesOnly yes

      Host k8s-main
        HostName 192.168.5.181
        ForwardAgent yes
        IdentityFile ~/.ssh/romantic
        IdentitiesOnly yes

      Host k8s-data1
        HostName 192.168.5.182
        ForwardAgent yes
        IdentityFile ~/.ssh/romantic
        IdentitiesOnly yes

      Host k8s-data2
        HostName 192.168.5.183
        ForwardAgent yes
        IdentityFile ~/.ssh/romantic
        IdentitiesOnly yes
    '';
  };
}
