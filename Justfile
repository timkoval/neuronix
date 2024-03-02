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


s-i3 mode="default":
  use utils.nu *; \
  nixos-switch shoukei_i3 {{mode}}


s-hypr mode="default":
  use utils.nu *; \
  nixos-switch shoukei_hyprland {{mode}}


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

ha mode="default":
  use utils.nu *; \
  darwin-build "harmonica" {{mode}}; \
  darwin-switch "harmonica" {{mode}}

air mode="default":
  use utils.nu *; \
  darwin-build "air" {{mode}}; \
  darwin-switch "air" {{mode}}

pro mode="default":
  use utils.nu *; \
  darwin-build "pro" {{mode}}; \
  darwin-switch "pro" {{mode}}

yabai-reload:
  launchctl kickstart -k "gui/502/org.nixos.yabai";
  launchctl kickstart -k "gui/502/org.nixos.skhd"; 

############################################################################
#
#  Colmena - Remote NixOS deployment
#
############################################################################

colmena-ssh-key:
  ssh-add /etc/agenix/ssh-key-romantic

dist:
  colmena apply --on '@dist-build'

dist-debug:
  colmena apply --on '@dist-build' --verbose --show-trace

aqua:
  colmena apply --on '@aqua'

ruby:
  colmena apply --on '@ruby'

kana:
  colmena apply --on '@kana'

tailscale_gw:
  colmena apply --on '@tailscale_gw'

pve-image:
  nom build .#tailscale_gw
  rsync -avz --progress --copy-links result root@s500plus:/var/lib/vz/dump/vzdump-qemu-tailscale_gw.vma.zst

  nom build .#aquamarine
  rsync -avz --progress --copy-links result root@s500plus:/var/lib/vz/dump/vzdump-qemu-aquamarine.vma.zst

  nom build .#ruby
  rsync -avz --progress --copy-links result root@gtr5:/var/lib/vz/dump/vzdump-qemu-ruby.vma.zst

  nom build .#kana
  rsync -avz --progress --copy-links result root@um560:/var/lib/vz/dump/vzdump-qemu-kana.vma.zst


############################################################################
#
#  RISC-V related commands
#
############################################################################

roll:
  colmena apply --on '@riscv'

roll-debug:
  colmena apply --on '@dist-build' --verbose --show-trace

nozomi:
  colmena apply --on '@nozomi'

yukina:
  colmena apply --on '@yukina'

############################################################################
#
# Aarch64 related commands
#
############################################################################

aarch:
  colmena apply --on '@aarch'

suzu:
  colmena apply --on '@suzu'

suzu-debug:
  colmena apply --on '@suzu' --verbose --show-trace

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
