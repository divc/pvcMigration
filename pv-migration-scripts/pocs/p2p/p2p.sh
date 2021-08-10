#!/bin/bash

# set -x

echo "p2p starting..."

echo "configuring..."
. configure.sh

echo "running..."

<<<<<<< HEAD
#cd ./source/
#. deploy.sh "$SRC_KUBE_CONTEXT" "$SRC_NS" "$SOURCE_PVC" "$GENERATE_DATA" "$CREATE_SRC_TEST_PVC"
=======
PWD=$(pwd)
>>>>>>> 8fb463894336e50e971eedd267dcd95747b66d74

cd $PWD/source/
. deploy.sh "$SRC_KUBE_CONTEXT" "$SRC_NS" "$SOURCE_PVC" "$GENERATE_DATA" "$CREATE_SRC_TEST_PVC"

<<<<<<< HEAD
cd ./dest/
. deploy.sh "$CLUSTER" "$DEST_PROJECT" "$DEST_ZONE" "$DEST_NS" "$DEST_PVC" "$SRC_NS" "$CREATE_DEST_TEST_PVC" "$SERVICE_ACCOUNT_PATH" "$SOURCE_CLUSTER_CERT" "$SOURCE_CLUSTER_API_HOST" #"$SA_PRIVATE_KEY_ID" "$SA_PRIVATE_KEY" "$SA_EMAIL" "$SA_CLIENT_ID"
=======
cd $PWD/dest/
. deploy.sh "$CLUSTER" "$DEST_PROJECT" "$DEST_ZONE_OR_REGION" "$DEST_NS" "$DEST_PVC" "$SRC_NS" "$CREATE_DEST_TEST_PVC" "$SERVICE_ACCOUNT_PATH" "$SOURCE_CLUSTER_CERT" "$SOURCE_CLUSTER_API_HOST"
>>>>>>> 8fb463894336e50e971eedd267dcd95747b66d74

echo "p2p complete!"