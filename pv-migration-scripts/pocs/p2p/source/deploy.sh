#!/bin/bash

# overview
# this bash script is responsible for deploying a script dir as configmap and a job.  
# The job runs entrypoint.sh and that job krsync to move files securely to this machine.

#set -x

if [ $# -ne 5 ]; then 
    echo "Illegal number of parameters"
    echo "USAGE ./deploy.sh SRC_KUBE_CONTEXT SRC_NS SOURCE_PVC GENERATE_DATA CREATE_TEST_PVC"
    exit 2
fi

SRC_KUBE_CONTEXT=$1     # context to use for job deploy
SRC_NS=$2               # namespace to deploy job into (and optionally test PVC)
SOURCE_PVC=$3           # source PVC name
GENERATE_DATA=$4        # yes/no; will generate 10 64mb test files in the PV
CREATE_TEST_PVC=$5      # yes/no; will create a test PVC using the SOURCE_PVC name

if [ -z "$SRC_OIDC_TOKEN" ]; then 
    echo "env var SRC_OIDC_TOKEN not set."
    echo "
    #Ex. 
    export SRC_OIDC_TOKEN=\$(gcloud config config-helper --format=\"value(credential.access_token)\")
    export SRC_OIDC_TOKEN=\$(k8s-okta oidc-token --client-id <CLIENTID> | jq -r .status.token)
    export SRC_OIDC_TOKEN=\$(aws eks get-token --cluster-name <CLUSTERNAME> | jq -r '.status.token')
    "
    exit 1 
fi

kubectl config use-context $SRC_KUBE_CONTEXT

kubectl delete job pv-migration-job-p2p -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN" 

# create configmaps for scripts dir
kubectl delete configmap source-pvc-mig-scripts-p2p -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN"
kubectl create configmap source-pvc-mig-scripts-p2p --from-file=scripts -n $SRC_NS --token="$SRC_OIDC_TOKEN"

if [[ "$CREATE_TEST_PVC" == "yes" ]]; then
    # DEPLOY TEST SOURCE PVC
    # remove comment below if destructive nature is required.
    # kubectl delete PersistentVolumeClaim $SOURCE_PVC -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN"

    sed -e "s#{SOURCE_PVC}#$SOURCE_PVC#g" \
    test-pvc-template.yaml > test-pvc.yaml

    kubectl apply -f test-pvc.yaml -n $SRC_NS --token="$SRC_OIDC_TOKEN"

    rm test-pvc.yaml
fi

# replace on the template (cheap templating)
sed -e "s#{SOURCE_PVC}#$SOURCE_PVC#g" \
    -e "s#{GENERATE_DATA}#$GENERATE_DATA#g" \
    p2p-template.yaml > job.yaml

kubectl apply -f job.yaml -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN" 

rm job.yaml

# get status
STATUS=""

until [ "$STATUS" == "running" ]
do
  STATUS=$(kubectl exec -it $(kubectl get pods -l=job-name=pv-migration-job-p2p -n $SRC_NS --token="$SRC_OIDC_TOKEN" -o jsonpath="{.items[0].metadata.name}") --token="$SRC_OIDC_TOKEN" -n $SRC_NS -- cat /p2p/status)
  echo Status: $STATUS
  sleep 5s
done