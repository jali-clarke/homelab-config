data "vault_generic_secret" "dev_git-ssh-key" {
  path = "kv/dev/git-ssh-key"
}

resource "hcloud_ssh_key" "dev_env" {
  name       = "dev_env"
  public_key = data.vault_generic_secret.dev_git-ssh-key.data["id_dev_env.pub"]
}

resource "hcloud_server" "cerberus" {
  name        = "cerberus"
  image       = "debian-11" 
  server_type = "cx11"
  location    = "nbg1"

  ssh_keys = [
    hcloud_ssh_key.dev_env.id
  ]

  delete_protection  = true
  rebuild_protection = true

  # NixOS images aren't provided by default, so we use nixos-infect
  user_data = <<-EOT
    #!/bin/sh
    curl https://raw.githubusercontent.com/elitak/nixos-infect/36e19e3b306abf70df6f4a6580b226b6a11a85f9/nixos-infect \
      | NIX_CHANNEL=nixpkgs-unstable bash 2>&1 \
      | tee /tmp/infect.log
  EOT
}
