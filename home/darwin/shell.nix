let
  envExtra = ''
    export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
  '';
  initExtra = ''
    arch=$(uname -m)

    if [ "aarch64" = "$arch" ] ||  [ "arm64" = "$arch" ]; then
      # >>> (miniforge)conda initialize >>>
      # !! Contents within this block are managed by 'conda init' !!
      if [ -f "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh" ]; then
          . "/opt/homebrew/Caskroom/miniforge/base/etc/profile.d/conda.sh"
      else
          export PATH="/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"
      fi
      # <<< conda initialize <<<
    elif [[ "x86_64" = "$arch" ]]; then
      # do nothing
      true
    fi
  '';
in {
  # Homebrew's default install location:
  #   /opt/homebrew for Apple Silicon
  #   /usr/local for macOS Intel
  # The prefix /opt/homebrew was chosen to allow installations
  # in /opt/homebrew for Apple Silicon and /usr/local for Rosetta 2 to coexist and use bottles.
  programs.bash = {
    enable = true;
    bashrcExtra = envExtra + initExtra;
  };
  programs.zsh = {
    enable = true;
    inherit envExtra initExtra;
  };
}
