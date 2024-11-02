# just is a command runner, Justfile is very similar to Makefile, but simpler.

# use nushell for shell commands
set shell := ["nu", "-c"]

############################################################################
#
#  Nix commands related to the local machine
#
############################################################################

i3 mode="default":
  use utils.nu *; \
  nixos-switch ai_i3 {{mode}}

hypr mode="default":
  use utils.nu *; \
  nixos-switch ai_hyprland {{mode}}

hetzner-tk mode="default":
  use utils.nu *; \
  nixos-switch ai_hyprland {{mode}} -- --target-host hetzner-tk


up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
upp input:
  nix flake lock --update-input {{input}}

history:
  nix profile history --profile /nix/var/nix/profiles/system

repl:
  nix repl -f flake:nixpkgs

clean:
  # remove all generations older than 7 days
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

gc:
  # garbage collect all unused nix store entries
  sudo nix store gc --debug
  sudo nix-collect-garbage --delete-old

gitgc:
  git reflog expire --expire-unreachable=now --all
  git gc --prune=now

############################################################################
#
#  Darwin related commands, harmonica is my macbook pro's hostname
#
############################################################################

darwin-set-proxy:
  sudo python3 scripts/darwin_set_proxy.py
  sleep 1sec

darwin-rollback:
  use utils.nu *; \
  darwin-rollback

air mode="default":
  use utils.nu *; \
  darwin-build "air" {{mode}}; \
  darwin-switch "air" {{mode}}

pro mode="default":
  use utils.nu *; \
  darwin-build "pro" {{mode}}; \
  darwin-switch "pro" {{mode}}

procs mode="default":
  use utils.nu *; \
  darwin-build "procs" {{mode}}; \
  darwin-switch "procs" {{mode}}

############################################################################
#
#  Misc, other useful commands
#
############################################################################

fmt:
  # format the nix files in this repo
  nix fmt

path:
   $env.PATH | split row ":"

nvim-test:
  rm -rf $"($env.HOME)/.config/astronvim/lua/user"
  rsync -avz --copy-links --chmod=D2755,F744 home/base/desktop/editors/neovim/astronvim_user/ $"($env.HOME)/.config/astronvim/lua/user"

nvim-clean:
  rm -rf $"($env.HOME)/.config/astronvim/lua/user"

# =================================================
# Emacs related commands
# =================================================

emacs-plist-path := "~/Library/LaunchAgents/org.nix-community.home.emacs.plist"

reload-emacs-cmd := if os() == "macos" {
    "launchctl unload " + emacs-plist-path
    + "\n"
    + "launchctl load " + emacs-plist-path
    + "\n"
    + "tail -f ~/Library/Logs/emacs-daemon.stderr.log"
  } else {
    "systemctl --user restart emacs.service"
    + "\n"
    + "systemctl --user status emacs.service"
  }

emacs-test:
  rm -rf $"($env.HOME)/.config/doom"
  rsync -avz --copy-links --chmod=D2755,F744 home/base/desktop/editors/emacs/doom/ $"($env.HOME)/.config/doom"
  doom clean
  doom sync

emacs-clean:
  rm -rf $"($env.HOME)/.config/doom/"

emacs-purge:
  doom purge
  doom clean
  doom sync

emacs-reload:
  doom sync
  {{reload-emacs-cmd}}
