#!/bin/bash
echo "Source sidecar starting..."

mkdir /p2p
echo -n 'starting' > /p2p/status

# echo "Installing kubectl"
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "Installing rsync"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends rsync

if [[ "$GENERATE_DATA" == "yes" ]]; then
    echo "Generating 10 64 MB files in the PVC (example data)..."

    for i in $(seq 1 10); do 
        filename=$(echo "testfile-$(echo `date +%Y-%m-%d-%H-%M-%S`)")
        echo "Creating file: $filename"
        dd if=/dev/urandom of=$PVC_DATA_PATH/$filename.bin bs=1M count=1 iflag=fullblock
        sleep 1s
    done

    echo "Data generated."
else
    echo "Data generated skipped."
fi

echo "Source sidecar started!"

echo -n 'running' > /p2p/status

# this allows attaching for debugging mounts, etc.
tail -f /dev/null


