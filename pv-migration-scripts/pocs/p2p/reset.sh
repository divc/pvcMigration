#!/bin/bash

echo "resetting p2p..."

echo "configuring..."
. configure.sh

# Dest

gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_PATH"
gcloud container clusters get-credentials $CLUSTER --zone $DEST_ZONE --project $DEST_PROJECT || exit 1

kubectl delete job pv-migration-job-p2p -n $DEST_NS --wait 
kubectl delete configmap dest-pvc-mig-scripts-p2p -n $DEST_NS --wait
kubectl delete PersistentVolumeClaim $DEST_PVC -n $DEST_NS --wait


# Source

kubectl config use-context $SRC_KUBE_CONTEXT

kubectl delete job pv-migration-job-p2p -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN" 
kubectl delete configmap source-pvc-mig-scripts-p2p -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN"
kubectl delete PersistentVolumeClaim $SOURCE_PVC -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN"

echo "resetting p2p... done"