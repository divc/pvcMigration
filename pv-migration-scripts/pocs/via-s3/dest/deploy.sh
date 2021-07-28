#!/bin/bash

# overview
# this bash script is responsible for deploying a script dir as configmap and a job.  
# The job runs entrypoint.sh and that job waits for GCS buckets/folders to be present and copies files the attached PVC 

if [$# -ne 8]; then 
    echo "Illegal number of parameters"
    echo "USAGE ./deploy.sh DEST_CLUSTER DEST_PROJECT DEST_ZONE DEST_NS DEST_PVC GCS_BUCKET GCS_PATH CREATE_TEST_PVC"
    exit 2
fi

# USAGE ./deploy.sh $DEST_CLUSTER $DEST_PROJECT $DEST_ZONE $DEST_NS $DEST_PVC $GCS_BUCKET $GCS_PATH $CREATE_TEST_PVC

DEST_CLUSTER=$1
DEST_PROJECT=$2
DEST_ZONE=$3
DEST_NS=$4
DEST_PVC=$5
GCS_BUCKET=$6
GCS_PATH=$7
CREATE_TEST_PVC=$8 # yes/no; will create a test PVC using the DEST_PVC name

gcloud container clusters get-credentials $DEST_CLUSTER --zone $DEST_ZONE --project $DEST_PROJECT

kubectl delete job pv-migration-job-via-s3 -n $DEST_NS

# create configmaps for scripts dir
kubectl delete configmap dest-pvc-mig-scripts-via-s3 -n $DEST_NS --wait
kubectl create configmap dest-pvc-mig-scripts-via-s3 --from-file=scripts -n $DEST_NS

kubectl delete secret pv-mig-secrets-via-s3 -n $DEST_NS
kubectl create secret generic pv-mig-secrets-via-s3  -n $DEST_NS --from-file=secrets

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
sed -e "s#{GCS_BUCKET}#$GCS_BUCKET#g" \
    -e "s#{GCS_PATH}#$GCS_PATH#g" \
    -e "s#{DEST_PVC}#$DEST_PVC#g" \
    -e "s#{DEST_PROJECT}#$DEST_PROJECT#g" \
    job-template.yaml > job.yaml

kubectl apply -f job.yaml -n $DEST_NS --wait

rm job.yaml

# #################### Wait for complete status ####################
STATUS="starting"

until [ "$STATUS" == "complete" ]
do
  STATUS=$(kubectl exec -it $(kubectl get pods -l=job-name=pv-migration-job-via-s3 -n $DEST_NS -o jsonpath="{.items[0].metadata.name}") -n $DEST_NS -- cat /p2p/status)
  echo Status: $STATUS
  sleep 5s
done