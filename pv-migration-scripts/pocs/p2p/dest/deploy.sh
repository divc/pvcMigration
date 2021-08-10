#!/bin/bash

# overview
# this bash script is responsible for deploying a script dir as configmap and a job.  
# The job runs entrypoint.sh and that job krsync to move files securely to this machine.

# auth:  the authentication to the SOURCE cluster is done using a token. 
# please set SRC_ODIC_TOKEN environment variable to an appropriate token before running

# set -x

if [ $# -ne 10 ]; then 
    echo "Illegal number of parameters"
    echo "USAGE ./deploy.sh CLUSTER DEST_PROJECT DEST_ZONE DEST_NS DEST_PVC SRC_NS CREATE_TEST_PVC SERVICE_ACCOUNT_PATH SOURCE_CLUSTER_CERT SOURCE_CLUSTER_API_HOST"
    exit 2
fi

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

CLUSTER=$1
DEST_PROJECT=$2
DEST_ZONE=$3
DEST_NS=$4
DEST_PVC=$5
#SRC_KUBE_CONTEXT=$6
SRC_KUBE_CONTEXT="p2p-cluster-context"
SRC_NS=$6
CREATE_TEST_PVC=$7 # yes/no; will create a test PVC using the DEST_PVC name
SERVICE_ACCOUNT_PATH=$8
SOURCE_CLUSTER_CERT=${9}
SOURCE_CLUSTER_API_HOST=${10}

# SA_PRIVATE_KEY_ID=${10}
# SA_PRIVATE_KEY=${11}
# SA_EMAIL=${12}
# SA_CLIENT_ID=${13}

# configure kubeconfig file
echo "
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $SOURCE_CLUSTER_CERT
    server: $SOURCE_CLUSTER_API_HOST
  name: p2p-cluster
contexts:
- context:
    cluster: p2p-cluster
    user: default-user
  name: p2p-cluster-context
current-context: p2p-cluster-context
kind: Config
preferences: {}
users:
- name: default-user
  user:
    token:
" > ./scripts/config
 
# echo "
# {
#   \"type\": \"service_account\",
#   \"project_id\": \"$DEST_PROJECT\",
#   \"private_key_id\": \"$SA_PRIVATE_KEY_ID\",
#   \"private_key\": \"$SA_PRIVATE_KEY\",
#   \"client_email\": \"$SA_EMAIL\",
#   \"client_id\": \"$SA_CLIENT_ID\",
#   \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",
#   \"token_uri\": \"https://oauth2.googleapis.com/token\",
#   \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",
#   \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/$(echo $SA_EMAIL | sed s/@/%40/)\"
# }
# " > ./secrets/service-account.json

# gcloud auth activate-service-account --key-file="./secrets/service-account.json" #"$SERVICE_ACCOUNT_PATH"
#gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_PATH"

#gcloud container clusters get-credentials $CLUSTER --zone $DEST_ZONE --project $DEST_PROJECT || exit 1

gcloud container clusters get-credentials $CLUSTER --region $DEST_ZONE --project $DEST_PROJECT || exit 1

kubectl delete job pv-migration-job-p2p -n $DEST_NS

# create configmaps for scripts dir
kubectl delete configmap dest-pvc-mig-scripts-p2p -n $DEST_NS --wait
kubectl create configmap dest-pvc-mig-scripts-p2p --from-file=scripts -n $DEST_NS

if [[ "$CREATE_TEST_PVC" == "yes" ]]; then
    # DEPLOY TEST DEST PVC
    # remove comment below if destructive nature is required.
    # kubectl delete PersistentVolumeClaim $DEST_PVC -n $DEST_NS --wait

    sed -e "s#{DEST_PVC}#$DEST_PVC#g" \
    test-pvc-template.yaml > test-pvc.yaml

    kubectl apply -f test-pvc.yaml -n $DEST_NS

    rm test-pvc.yaml
fi

# replace on the template (cheap/hacky templating)
sed -e "s#{SOURCE_CLUSTER}#$CLUSTER#g" \
    -e "s#{DEST_PVC}#$DEST_PVC#g" \
    -e "s#{OIDC_TOKEN}#$SRC_OIDC_TOKEN#g" \
    -e "s#{KUBE_CONTEXT}#$SRC_KUBE_CONTEXT#g" \
    -e "s#{SRC_NS}#$SRC_NS#g" \
    p2p-template.yaml > job.yaml

kubectl apply -f job.yaml -n $DEST_NS --wait

rm job.yaml

# #################### Wait for complete status ####################
STATUS="starting"

until [ "$STATUS" == "complete" ]
do
  STATUS=$(kubectl exec -it $(kubectl get pods -l=job-name=pv-migration-job-p2p -n $DEST_NS -o jsonpath="{.items[0].metadata.name}") -n $DEST_NS -- cat /p2p/status)
  echo Status: $STATUS
  sleep 5s
done