# nixos-generate -f install-iso --system x86_64-linux --flake './base-flake.nix#weedle'
# the above doesn't work for some reason :(

sudo nixos-generate -f install-iso --system x86_64-linux -c installation-image.nix
