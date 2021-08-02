#!/bin/bash

# set -x

echo "p2p starting..."

echo "configuring..."
. configure.sh

echo "running..."

cd ./source/
. deploy.sh $SRC_KUBE_CONTEXT $SRC_NS $SOURCE_PVC $GENERATE_DATA $CREATE_SRC_TEST_PVC


cd ./dest/
. deploy.sh $CLUSTER $DEST_PROJECT $DEST_ZONE $DEST_NS $DEST_PVC $SRC_NS $CREATE_DEST_TEST_PVC $SERVICE_ACCOUNT_PATH $SOURCE_CLUSTER_CERT $SOURCE_CLUSTER_API_HOST  #$SA_PRIVATE_KEY_ID $SA_PRIVATE_KEY $SA_EMAIL $SA_CLIENT_ID

echo "p2p complete!"