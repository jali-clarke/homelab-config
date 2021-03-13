set -xe

WEEDLE_IP="192.168.0.102"
REMOTE_WORKSPACE="/tmp/deployment"

ssh pi@${WEEDLE_IP} -- "rm -rf ${REMOTE_WORKSPACE} && mkdir -p ${REMOTE_WORKSPACE}"

scp bundled-configuration.nix pi@${WEEDLE_IP}:${REMOTE_WORKSPACE}/configuration.nix
scp -r ../common pi@${WEEDLE_IP}:${REMOTE_WORKSPACE}/common

ssh -t pi@${WEEDLE_IP} -- "sudo rm -rf /etc/nixos/configuration.nix /etc/nixos/common && sudo cp -r ${REMOTE_WORKSPACE}/* /etc/nixos && sudo nixos-rebuild switch"

