



aws sts get-session-token \
--serial-number arn:aws:iam::966891400085:mfa/divyanshc@google.com \
--token-code 951841

Installing Velero on MacOS  

Step 1: brew install velero

For other OSes -- https://velero.io/docs/v1.6/basic-install/



Install and configure the server components for GCP 

BUCKET=pvc-cluster-valero-bucket
gsutil mb gs://$BUCKET/




velero install --use-restic --provider gcp --plugins velero/velero-plugin-for-gcp:v1.0.0 --bucket pvc-cluster-valero-bucket --secret-file ./credentials-velero --wait




velero backup create pv-backup-1 --exclude-resources pods,secrets,deployments,services,replicaset,endpointslice,configmap,endpoints,namespace,resourcequota,serviceaccount --include-namespaces default --include-cluster-resources=false --wait




Velero AWS 

BUCKET=pvc-cluster-valero-bucket
REGION=us-east-2




velero install \
    --use-restic \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.2.0 \
    --bucket $BUCKET \
    --backup-location-config region=$REGION \
    --snapshot-location-config region=$REGION \
    --secret-file ./credentials-velero-aws




ssh -i "divc-key-pai.pem" ec2-user@ec2-18-117-162-111.us-east-2.compute.amazonaws.com


kubectl -n default annotate pod/wordpress-mysql-866bf45d65-7thrz backup.velero.io/backup-volumes=mysql-persistent-storage

kubectl -n default annotate pod/wordpress-86999dc7d9-62dxv   backup.velero.io/backup-volumes=wordpress-persistent-storage

velero backup create pv-backup-1 --exclude-resources events,Event,secrets,deployments,services,replicaset,endpointslice,configmap,endpoints,namespace,resourcequota,serviceaccount --include-namespaces default --include-cluster-resources=false --wait

velero backup create pv-backup-1 --include-namespaces default --include-cluster-resources=false --wait


velero backup describe pv-backup-2 --details


286.1MB



Transfer service 

aws iam create-user --user-name gcp-transfer-service


aws iam put-user-policy \
  --user-name gcp-transfer-service \
  --policy-name gcp-transfer-service \
  --policy-document file://gcp-trasnfer-service-policy.json

aws iam create-access-key --user-name gcp-transfer-service


aws s3 sync s3://pvc-cluster-valero-bucket .

gsutil -m cp -R . gs://pvc-cluster-valero-bucket



Velero GCP 

gcloud config list
PROJECT_ID=$(gcloud config get-value project)

gcloud iam service-accounts create velero-sa \
    --display-name "Velero service account"

gcloud iam service-accounts list

SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:Velero service account" \
  --format 'value(email)')

echo $SERVICE_ACCOUNT_EMAIL

ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)

gcloud iam roles create velero.server \
    --project $PROJECT_ID \
    --title "Velero Server" \
    --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
    --role projects/$PROJECT_ID/roles/velero.server

echo $BUCKET

gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${BUCKET}

gcloud iam service-accounts keys create credentials-velero-gcp \
    --iam-account $SERVICE_ACCOUNT_EMAIL


velero install \
    --use-restic \
    --provider gcp \
    --plugins velero/velero-plugin-for-gcp:v1.2.0 \
    --bucket $BUCKET \
    --secret-file ./credentials-velero-gcp \
    --wait


velero restore create --from-backup pv-backup-1 --wait