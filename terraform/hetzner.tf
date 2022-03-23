data "vault_generic_secret" "dev_git-ssh-key" {
  path = "kv/dev/git-ssh-key"
}

resource "hcloud_ssh_key" "dev_env" {
  name       = "dev_env"
  public_key = data.vault_generic_secret.dev_git-ssh-key.data["id_dev_env.pub"]
}

resource "hcloud_server" "cerberus" {
  name        = "cerberus"
  # NixOS images aren't provided by default.  you'll have to do something like this
  # https://github.com/nix-community/nixos-install-scripts/blob/master/hosters/hetzner-cloud/nixos-install-hetzner-cloud.sh
  image       = "debian-11" 
  server_type = "cx11"
  location    = "nbg1"

  ssh_keys = [
    hcloud_ssh_key.dev_env.id
  ]

  delete_protection  = true
  rebuild_protection = true
}
