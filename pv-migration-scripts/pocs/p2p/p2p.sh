#!/bin/bash

# set -x

echo "p2p starting..."

echo "configuring..."
. configure.sh

echo "running..."

PWD=$(pwd)

cd $PWD/source/
. deploy.sh "$SRC_KUBE_CONTEXT" "$SRC_NS" "$SOURCE_PVC" "$GENERATE_DATA" "$CREATE_SRC_TEST_PVC"

cd ../dest/
. deploy.sh "$CLUSTER" "$DEST_PROJECT" "$DEST_ZONE_OR_REGION" "$DEST_NS" "$DEST_PVC" "$SRC_NS" "$CREATE_DEST_TEST_PVC" "$SERVICE_ACCOUNT_PATH" "$SOURCE_CLUSTER_CERT" "$SOURCE_CLUSTER_API_HOST" "$IS_REGIONAL_CLUSTER" "$SOURCE_PVC_SIZE"

echo "p2p complete!"