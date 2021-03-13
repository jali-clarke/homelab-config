# nixos-generate -f sd-aarch64-installer --system aarch64-linux --flake './base-flake.nix#speet'
# the above doesn't work for some reason :(

sudo nixos-generate -f sd-aarch64-installer --system aarch64-linux -c installation-image.nix
