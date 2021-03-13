set -xe

MASTER_IP="192.168.0.102"

mkdir -p ~/.kube
sudo mkdir -p /var/lib/kubernetes/secrets 
sudo chmod a+rwx /var/lib/kubernetes/secrets

ssh pi@${MASTER_IP} -- "cat /etc/kubernetes/cluster-admin.kubeconfig" > ~/.kube/config
ssh pi@${MASTER_IP} -- "cat /var/lib/kubernetes/secrets/ca.pem" > /var/lib/kubernetes/secrets/ca.pem
ssh pi@${MASTER_IP} -- "cat /var/lib/kubernetes/secrets/cluster-admin.pem" > /var/lib/kubernetes/secrets/cluster-admin.pem
ssh -t pi@${MASTER_IP} -- "sudo cp /var/lib/kubernetes/secrets/cluster-admin-key.pem /tmp/cluster-admin-key.pem && sudo chmod a+r /tmp/cluster-admin-key.pem"
ssh pi@${MASTER_IP} -- "cat /tmp/cluster-admin-key.pem" > /var/lib/kubernetes/secrets/cluster-admin-key.pem
ssh -t pi@${MASTER_IP} -- "sudo rm /tmp/cluster-admin-key.pem"
