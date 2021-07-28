#!/bin/bash

# main entry point script for starting the Via S3 migration

echo "via-s3 starting..."

# Source 
GENERATE_DATA="yes"                 # yes/no; will generate 10 64mb test files in the PV
CREATE_TEST_PVC="yes"               # yes/no; will create a test PVC using the SOURCE_PVC name
SRC_NS="alfa"                       # namespace to deploy job into (and optionally test PVC)
SOURCE_PVC="source-sidecar-pvc-p2p" # source PVC name
#SRC_OIDC_TOKEN=""                  # OIDC token is used for authenication to the AWS cluster; set this here or via shell env var
SRC_KUBE_CONTEXT="dev.k8s.au-infrastructure.com"

cd ./source/
./deploy.sh $SRC_KUBE_CONTEXT $SRC_NS $SOURCE_PVC $GENERATE_DATA $CREATE_TEST_PVC


# Destination
CREATE_TEST_PVC="yes"               # yes/no; will create a test PVC using the DEST_PVC name
DEST_NS="default"                   # destination namespace
CLUSTER="au-poc-cluster-dest"       # destination cluster
DEST_PVC="dest-sidecar-pvc-p2p"     # destination PVC name
DEST_ZONE="us-east4-a"              # destination zone (should be zone where cluster is)
DEST_PROJECT="gft-amer-rtai-test"   # destination project id

cd ../dest/
./deploy.sh $CLUSTER $DEST_PROJECT $DEST_ZONE $DEST_NS $DEST_PVC $SRC_KUBE_CONTEXT $SRC_NS $CREATE_TEST_PVC

echo "via-s3 complete!"