{ pkgs }:
pkgs.writeScriptBin "load_ssh_key" ''
  #!${pkgs.runtimeShell} -xe

  if [ -z "$SECRETS_PASSPHRASE" ]; then
    echo "SECRETS_PASSPHRASE not set"
    exit 1
  fi

  mkdir -p ~/.ssh

  ${pkgs.ccrypt}/bin/ccat -E SECRETS_PASSPHRASE ${../secrets/id_rsa_nixops.cpt} > ~/.ssh/id_rsa_nixops
  chmod 600 ~/.ssh/id_rsa_nixops
  ${pkgs.openssh}/bin/ssh-keygen -y -f ~/.ssh/id_rsa_nixops > ~/.ssh/id_rsa_nixops.pub
  chmod 644 ~/.ssh/id_rsa_nixops.pub
''
