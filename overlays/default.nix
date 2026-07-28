args:
# execute and import all overlay files in the current directory with the given args
builtins.map
(f: (import (./. + "/${f}") args)) # execute and import the overlay file

(builtins.filter # find all overlay files in the current directory
  
  (
    f:
      f
      != "default.nix" # ignore default.nix
      && f != "README.md" # ignore README.md
      && f != "grok-build.nix" # wired centrally in nixosSystem.nix / macosSystem.nix
  )
  (builtins.attrNames (builtins.readDir ./.)))
