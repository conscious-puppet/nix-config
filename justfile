default:
    @just --list

# Auto-format the source tree
fmt:
    treefmt

# switch work home-manager config
hm-switch:
  USER="abhishek.singh1" nix run .#work -- switch

# switch nix config (unused)
nx-switch *ARGS:
  /run/wrappers/bin/sudo nixos-rebuild switch --flake .#nixos {{ARGS}}

# switch nix-darwin + home-manager config
dw-switch *ARGS:
  sudo darwin-rebuild switch --flake .#puppeteer
