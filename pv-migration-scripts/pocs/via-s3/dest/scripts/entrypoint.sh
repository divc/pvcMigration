#!/bin/bash
echo "Destination sidecar starting..."

mkdir /p2p
echo -n 'starting' > /p2p/status

echo "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "Installing gsutil"
gcloud components install gsutil

# auth with service account
gcloud auth activate-service-account --key-file=/home/secrets/service-account.json

# at this point, we need to check if bucket exists if so check for migration files
echo -n 'waiting_for_bucket' > /p2p/status

HAS_BUCKET=$(if [[ "$(gsutil ls | grep $GCS_BUCKET)" == "$GCS_BUCKET" ]]; then echo "yes"; fi)

until [ "$HAS_BUCKET" == "yes" ]
do
  HAS_BUCKET=$(if [[ "$(gsutil ls | grep $GCS_BUCKET)" == "$GCS_BUCKET" ]]; then echo "yes"; fi)
  echo "Bucket '$GCS_BUCKET' not found, retrying in 10s"
  sleep 10s
done

if [[ ! -z "$GCS_PATH" ]]; then
    HAS_PATH=$(if [[ "$(gsutil ls $GCS_BUCKET | grep "$GCS_BUCKET$GCS_PATH")" == "$GCS_BUCKET$GCS_PATH" ]]; then echo "yes"; fi)

    until [ "$HAS_PATH" == "yes" ]
    do
        HAS_BUCKET=$(if [[ "$(gsutil ls | grep $GCS_BUCKET)" == "$GCS_BUCKET" ]]; then echo "yes"; fi)
        echo "Bucket path '$GCS_BUCKET$GCS_PATH' not found, retrying in 10s"
        sleep 10s
    done
fi

# copy files from gcs to local pvc
echo -n 'copying' > /p2p/status
gsutil -p $DEST_PROJECT cp $GCS_BUCKET$GCS_PATH /home/pvc

echo -n 'complete' > /p2p/status
# this allows attaching for debugging mounts, etc.
tail -f /dev/null