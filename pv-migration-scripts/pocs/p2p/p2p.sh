#!/bin/bash

# overview

# set -x

echo "p2p starting..."

# Source 
GENERATE_DATA="yes"                                 # yes/no; will generate 10 64mb test files in the PV
CREATE_TEST_PVC="yes"                               # yes/no; will create a test PVC using the SOURCE_PVC name
SRC_NS="alfa"                                       # source namespace to deploy job into (and optionally test PVC)
SOURCE_PVC="source-sidecar-pvc-p2p"                 # source PVC name
SRC_KUBE_CONTEXT="dev.k8s.au-infrastructure.com"    # source kube-context

cd ./source/
./deploy.sh $SRC_KUBE_CONTEXT $SRC_NS $SOURCE_PVC $GENERATE_DATA $CREATE_TEST_PVC

# Destination
CREATE_TEST_PVC="yes"                               # yes/no; will create a test PVC using the DEST_PVC name
DEST_NS="default"                                   # dest namespace to deploy job into (and optionally test PVC)
CLUSTER="au-poc-cluster-dest"                       # dest cluster name
DEST_PVC="dest-sidecar-pvc-p2p"                     # dest PVC name
DEST_ZONE="us-east4-a"                              # dest zone
DEST_PROJECT="gft-amer-rtai-test"                   # dest project id
SERVICE_ACCOUNT_PATH="secrets/service-account.key"  # Populate with service account path (do not change unless you changed the code or file location)

cd ../dest/
./deploy.sh $CLUSTER $DEST_PROJECT $DEST_ZONE $DEST_NS $DEST_PVC $SRC_KUBE_CONTEXT $SRC_NS $CREATE_TEST_PVC $SERVICE_ACCOUNT_PATH

echo "p2p complete!"