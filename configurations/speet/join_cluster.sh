set -xe

MASTER_IP="192.168.0.102"
WORKER_IP="192.168.0.101"

ssh -t pi@${MASTER_IP} -- "sudo cat /var/lib/kubernetes/secrets/apitoken.secret > /tmp/apitoken.secret"
API_TOKEN=$(ssh pi@${MASTER_IP} -- "cat /tmp/apitoken.secret")
ssh -t pi@${MASTER_IP} -- "sudo rm /tmp/apitoken.secret"
ssh -t pi@${WORKER_IP} -- "echo ${API_TOKEN} | sudo nixos-kubernetes-node-join"

