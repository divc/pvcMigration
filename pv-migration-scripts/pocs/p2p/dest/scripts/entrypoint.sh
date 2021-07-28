#!/bin/bash
echo "Destination sidecar starting..."

mkdir /p2p
echo -n 'starting' > /p2p/status

echo "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "Installing rsync"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends rsync

########################## Remove and supply other auth mechinism ##########################
mkdir ~/.kube
cp /home/config ~/.kube
kubectl config set-credentials default-user --token="$OIDC_TOKEN"
########################## Remove and supply other auth mechinism ##########################

kubectl config use-context $KUBE_CONTEXT

SRC_POD=$(kubectl get pods -l=job-name=pv-migration-job-p2p -n $SRC_NS -o jsonpath="{.items[0].metadata.name}")

# run krsync
echo "syncing between $SRC_POD@$SRC_NS and this pod in dir: $THIS_DIR"
./home/krsync -av --progress --stats $SRC_POD@$SRC_NS:$SRC_DIR $THIS_DIR

echo -n 'complete' > /p2p/status

# this allows attaching for debugging mounts, etc.
tail -f /dev/null