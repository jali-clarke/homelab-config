set -xe

SPEET_IP="192.168.0.101"
REMOTE_WORKSPACE="/tmp/deployment"

ssh pi@${SPEET_IP} -- "rm -rf ${REMOTE_WORKSPACE} && mkdir -p ${REMOTE_WORKSPACE}"

scp bundled-configuration.nix pi@${SPEET_IP}:${REMOTE_WORKSPACE}/configuration.nix
scp -r ../common pi@${SPEET_IP}:${REMOTE_WORKSPACE}/common

ssh -t pi@${SPEET_IP} -- "sudo rm -rf /etc/nixos/configuration.nix /etc/nixos/common && sudo cp -r ${REMOTE_WORKSPACE}/* /etc/nixos && sudo nixos-rebuild switch"

