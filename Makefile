deploy: 
	sudo nixos-rebuild switch --flake .

debug:
	sudo nixos-rebuild switch --flake . --show-trace --verbose

update:
	nix flake update

history:
	nix profile history --profile /nix/var/nix/profiles/system

gc:
	# remove all generations older than 7 days
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

	# garbage collect all unused nix store entries
	sudo nix store gc --debug

darwin-set-proxy:
	sudo python3 scripts/darwin_set_proxy.py

darwin: darwin-set-proxy
	nix build .#darwinConfigurations.harmonica.system \
	  --extra-experimental-features 'nix-command flakes'
	./result/sw/bin/darwin-rebuild switch --flake .

darwin-debug: darwin-set-proxy
	nix build .#darwinConfigurations.harmonica.system \
	  --show-trace --verbose \
	  --extra-experimental-features 'nix-command flakes'
	./result/sw/bin/darwin-rebuild switch --flake . --show-trace --verbose

idols:
	nixos-rebuild --flake .#aquamarine --target-host aquamarine --build-host aquamarine switch --use-remote-sudo
	nixos-rebuild --flake .#ruby --target-host ruby --build-host ruby switch --use-remote-sudo
	nixos-rebuild --flake .#kana --target-host kana --build-host kana switch --use-remote-sudo

idols-debug:
	nixos-rebuild --flake .#aquamarine --target-host aquamarine --build-host aquamarine switch --use-remote-sudo --show-trace --verbose
	nixos-rebuild --flake .#ruby --target-host ruby --build-host ruby switch --use-remote-sudo --show-trace --verbose
	nixos-rebuild --flake .#kana --target-host kana --build-host kana switch --use-remote-sudo --show-trace --verbose

idols-image:
	# take image for idols, and upload the image to proxmox nodes.
	nom build .#aquamarine
	scp result/vzdump-qemu-*.vma.zst root@gtr5:/var/lib/vz/dump

	nom build .#ruby
	scp result/vzdump-qemu-*.vma.zst root@s500plus:/var/lib/vz/dump

	nom build .#kana
	scp result/vzdump-qemu-*.vma.zst root@um560:/var/lib/vz/dump

fmt:
	# format the nix files in this repo
	nix fmt

.PHONY: clean  
clean:  
	rm -rf result
