#!/bin/sh

#NAMESPACE=$1
#PVC_NAME=$2
NAMESPACE=default
PVC_NAME=
NEW_NAMESPACE=sample
VELERO_SERVICE_ACCOUNT_NAME=velero-sa
VELERO_ROLE_NAME=velero.server.role
VELERO_ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)
BUCKET=pvc-cluster-valero-bucket #Change the bucket name based on the naming convention and policies 


PROJECT_ID=$(gcloud config get-value project)
echo "Setting Project ID to $PROJECT_ID"


echo "Creating Velero Service Account ($VELERO_SERVICE_ACCOUNT_NAME)"
gcloud iam service-accounts create $VELERO_SERVICE_ACCOUNT_NAME \
    --display-name "Velero service account"

VELERO_SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
  --filter="Email:$VELERO_SERVICE_ACCOUNT_NAME" \
  --format 'value(email)')

echo "Velero Service Account account created ($VELERO_SERVICE_ACCOUNT_EMAIL)"

gcloud iam roles create $VELERO_ROLE_NAME \
    --project $PROJECT_ID \
    --title "Velero Server" \
    --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$VELERO_SERVICE_ACCOUNT_EMAIL \
    --role projects/$PROJECT_ID/roles/velero.server.role

gsutil iam ch serviceAccount:$VELERO_SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${BUCKET}

echo "Velero Server Role created [$VELERO_ROLE_NAME]"

gcloud iam service-accounts keys create gcp-credentials-velero \
    --iam-account $VELERO_SERVICE_ACCOUNT_EMAIL



gsutil ls gs://$BUCKET/
if [[ $? -ne 0 ]]; then
  echo "$BUCKET does not exist. Creating one...."
  gsutil mb gs://$BUCKET/
  echo "$BUCKET created"
fi

echo "Installing Velero"

velero install --use-restic --provider gcp --plugins velero/velero-plugin-for-gcp:v1.0.0 --bucket $BUCKET --secret-file ./gcp-credentials-velero --wait

echo "Starting backup via Velero"
EPOCH=`date +%s`
#velero backup create pv-backup-$EPOCH --exclude-resources secrets,deployments,services,replicaset,endpointslice,configmap,endpoints,namespace,resourcequota,serviceaccount --include-namespaces $NAMESPACE --include-cluster-resources=false --wait

velero backup create pv-backup-$EPOCH --include-namespaces $NAMESPACE --include-cluster-resources=false --wait

velero restore create pv-restore-$EPOCH --from-backup pv-backup-$EPOCH --namespace-mappings $NAMESPACE:$NEW_NAMESPACE --wait