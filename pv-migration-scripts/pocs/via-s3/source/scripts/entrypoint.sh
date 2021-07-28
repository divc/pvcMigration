#!/bin/bash
echo "Source sidecar starting..."

mkdir /p2p
echo -n 'starting' > /p2p/status

DEBIAN_FRONTEND=noninteractive

apt-get update

echo "Installing AWS CLI"
apt-get install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm awscliv2.zip
rm -rf ./aws
cp /home/secrets/credentials ~/.aws/credentials #copy aws creds to right location

echo "Check gcloud version:"
gcloud --version

echo "Check aws version:"
aws --version

if [[ "$GENERATE_DATA" == "yes" ]]; then
    echo "Generating 10 64 MB files in the PVC (example data)..."

    for i in $(seq 1 10); do 
        filename=$(echo "testfile-$(echo `date +%Y-%m-%d-%H-%M-%S`)")
        echo "Creating file: $filename"
        dd if=/dev/urandom of=$PVC_FULL_DATA_PATH/$filename.bin bs=1M count=1 iflag=fullblock
        sleep 1s
    done

    echo "Data generated."
else
    echo "Data generated skipped."
fi

# copy to s3
FULL_BUCKET_PATH="s3://$S3_BUCKET/$SOURCE_PVC"
echo "Copying data from $PVC_FULL_DATA_PATH to $FULL_BUCKET_PATH"
aws s3 cp --recursive $PVC_FULL_DATA_PATH $FULL_BUCKET_PATH

echo "Source sidecar complete!"

echo -n 'complete' > /p2p/status

# this allows attaching for debugging mounts, etc.
tail -f /dev/null


