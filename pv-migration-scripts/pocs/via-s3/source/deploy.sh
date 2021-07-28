#!/bin/bash

# overview
# this bash script is responsible for deploying a script dir as configmap and a job.  
# The job runs entrypoint.sh and that job krsync to move files securely to this machine.

#set -x

if [$# -ne 7]; then 
    echo "Illegal number of parameters"
    echo "USAGE ./deploy.sh SRC_KUBE_CONTEXT SRC_NS SOURCE_PVC PVC_DATA_PATH S3_BUCKET GENERATE_DATA CREATE_TEST_PVC"
    echo "
    SRC_KUBE_CONTEXT: kube context to use for creating this job
    SRC_NS: namespace to deploy job into (and optionally test PVC)
    SOURCE_PVC: source PVC name
    PVC_DATA_PATH: path to the data
    S3_BUCKET: S3 bucket to copy data to
    GENERATE_DATA: yes/no; will generate 10 64mb test files in the PV
    CREATE_TEST_PVC: yes/no; will create a test PVC using the SOURCE_PVC name
    "
    exit 2
fi

SRC_KUBE_CONTEXT=$1     # kube context to use for creating this job
SRC_NS=$2               # namespace to deploy job into (and optionally test PVC)
SOURCE_PVC=$3           # source PVC name
PVC_DATA_PATH=$4        # path to the data
S3_BUCKET=$5            # S3 bucket to copy data to
GENERATE_DATA=$6        # yes/no; will generate 10 64mb test files in the PV
CREATE_TEST_PVC=$7      # yes/no; will create a test PVC using the SOURCE_PVC name



# #SRC_OIDC_TOKEN="" # set this here or via env var

# GENERATE_DATA="yes"     # yes/no; will generate 10 64mb test files in the PV
# CREATE_TEST_PVC="yes"   # yes/no; will create a test PVC using the SOURCE_PVC name
# SRC_NS="alfa"           # namespace to deploy job into (and optionally test PVC)
# SOURCE_PVC="source-sidecar-pvc-p2p" # source PVC name
# # Configure the SOURCE cluster token, context, and namespace
# # AWS Dev Config
# #SRC_OIDC_TOKEN="" # set this here or via env var
# SRC_KUBE_CONTEXT="dev.k8s.au-infrastructure.com"


# required env vars
S3_BUCKET="rangeli-test-mig-1" # destination bucket
SRC_KUBE_CONTEXT="dev.k8s.au-infrastructure.com"
SRC_NS="alfa"
DEPOYMENT_NAME="pod/cnc-edge-conn-lg-redis-load-generator-0"
SOURCE_PVC="redis-dataset-cnc-edge-conn-lg-redis-load-generator-0"
PVC_DATA_PATH="/home/pvc"
GENERATE_DATA="no"

if [ -z "$SRC_OIDC_TOKEN" ]; then echo "SRC_OIDC_TOKEN not set." && exit 1; fi

#Ex. 
#SRC_OIDC_TOKEN=$(gcloud config config-helper --format="value(credential.access_token)")
#SRC_OIDC_TOKEN=$(k8s-okta oidc-token --client-id 0oa54lqa1zwIWea3P2p7 | jq -r .status.token)

kubectl config use-context $SRC_KUBE_CONTEXT

kubectl delete job pv-migration-job-via-s3 -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN" 

# create configmaps for scripts dir
kubectl delete configmap source-pvc-mig-scripts-via-s3 -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN"
kubectl create configmap source-pvc-mig-scripts-via-s3 --from-file=scripts -n $SRC_NS --token="$SRC_OIDC_TOKEN"

# create secrets
kubectl delete secret pv-mig-secrets-via-s3 -n $SRC_NS
kubectl create secret generic pv-mig-secrets-via-s3  -n $SRC_NS --from-file=AWS_SECRET_ACCESS_KEY --token="$SRC_OIDC_TOKEN"

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
sed -e  "s#{PVC_DATA_PATH}#$PVC_DATA_PATH#g" /
    -e  "s#{S3_BUCKET}#$S3_BUCKET#g" /
    -e  "s#{GENERATE_DATA}#$GENERATE_DATA#g" /
    -e  "s#{SOURCE_PVC}#$SOURCE_PVC#g" /
    
job-template.yaml  > job.yaml

kubectl apply -f job.yaml -n $SRC_NS --wait --token="$SRC_OIDC_TOKEN" 

rm job.yaml

# get status
STATUS=""

until [ "$STATUS" == "complete" ]
do
  STATUS=$(kubectl exec -it $(kubectl get pods -l=job-name=pv-migration-job-via-s3 -n $SRC_NS --token="$SRC_OIDC_TOKEN" -o jsonpath="{.items[0].metadata.name}") --token="$SRC_OIDC_TOKEN" -n $SRC_NS -- cat /p2p/status)
  echo Status: $STATUS
  sleep 5s
done