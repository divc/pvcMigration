#!/bin/sh

echo "Importing configuration file (configure-env.sh)..."
. configure-env.sh


if [[ $ENVIRONMENT_TO_CONFIGURE = "GCP" || $ENVIRONMENT_TO_CONFIGURE = "BOTH" ]]; then
    echo "Setting up GCP environment..."
    export GCP_PROJECT_ID=$(gcloud config get-value project)
    echo "Setting Project ID to $GCP_PROJECT_ID"


    echo "Creating Velero Service Account ($GCP_VELERO_SERVICE_ACCOUNT_NAME)"
    gcloud iam service-accounts create $GCP_VELERO_SERVICE_ACCOUNT_NAME \
        --display-name "Velero service account"

    export GCP_VELERO_SERVICE_ACCOUNT_EMAIL="${GCP_VELERO_SERVICE_ACCOUNT_NAME}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"

    echo "Velero Service Account account created ($GCP_VELERO_SERVICE_ACCOUNT_EMAIL)"

    gcloud iam roles create $GCP_VELERO_ROLE_NAME \
        --project $GCP_PROJECT_ID \
        --title "Velero Server" \
        --permissions "$(IFS=","; echo "${GCP_ROLE_PERMISSIONS[*]}")"

    gcloud projects add-iam-policy-binding $GCP_PROJECT_ID \
        --member serviceAccount:$GCP_VELERO_SERVICE_ACCOUNT_EMAIL \
        --role projects/$GCP_PROJECT_ID/roles/velero.server.role

    gsutil iam ch serviceAccount:$GCP_VELERO_SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${GCP_BUCKET}

    echo "Velero Server Role created [$GCP_VELERO_ROLE_NAME]"

    gcloud iam service-accounts keys create gcp-credentials-velero \
        --iam-account $GCP_VELERO_SERVICE_ACCOUNT_EMAIL

    chmod 666 ./gcp-credentials-velero

    gsutil ls gs://$GCP_BUCKET/
    if [[ $? -ne 0 ]]; then
    echo "$GCP_BUCKET does not exist. Creating one...."
    gsutil mb gs://$GCP_BUCKET/
    echo "$GCP_BUCKET created"
    fi

    echo "Setting KUBECONFIG to point to ${GCP_CLUSTER_NAME}..."
    gcloud container clusters get-credentials $GCP_CLUSTER_NAME --region $GCP_REGION --project $GCP_PROJECT_ID

    echo "Installing Velero"

    velero install --use-restic --provider gcp --plugins velero/velero-plugin-for-gcp:v1.0.0 --bucket $GCP_BUCKET --secret-file ./gcp-credentials-velero --wait

    echo "Velero configured and installed on GKE cluster"

    velero backup-location get 

    kubectl logs deployment/velero -n velero | grep error 
fi 

if [[ $ENVIRONMENT_TO_CONFIGURE = "AWS" || $ENVIRONMENT_TO_CONFIGURE = "BOTH" ]]; then
    echo "Setting up AWS environment..."

    echo "Creating AWS Bucket $AWS_BUCKET in region $AWS_REGION"
    aws s3api create-bucket \
    --bucket $AWS_BUCKET \
    --region $AWS_REGION \
    --create-bucket-configuration LocationConstraint=$AWS_REGION

    sleep 2 
    echo "Creating Velero Service Account ($AWS_VELERO_SERVICE_ACCOUNT_NAME)"
    aws iam create-user --user-name $AWS_VELERO_SERVICE_ACCOUNT_NAME

    aws iam put-user-policy \
    --user-name $AWS_VELERO_SERVICE_ACCOUNT_NAME \
    --policy-name $AWS_VELERO_POLICY_NAME \
    --policy-document file://aws-velero-policy.json

    sleep 2
    touch ./aws-credentials-velero

    OUTPUT=$(aws iam create-access-key --user-name $AWS_VELERO_SERVICE_ACCOUNT_NAME --output text)

    echo $OUTPUT
    retval=$?

    if [ $retval -ne 0 ]; then
    echo "Failed to get session values"
    exit 1
    fi

    AWS_SA_ACCESS=$(echo $OUTPUT | awk '{print $2}')
    AWS_SA_SECRET=$(echo $OUTPUT | awk '{print $4}')

    echo $AWS_SA_ACCESS
    echo $AWS_SA_SECRET

    # Update the line numbers, 12-14 to reflect your specific credentials file
    sed -ie "2s|.*|aws_access_key_id = $AWS_SA_ACCESS|" ./aws-credentials-velero
    sed -ie "3s|.*|aws_secret_access_key = $AWS_SA_SECRET|" ./aws-credentials-velero

    sleep 2
    echo "Setting KUBECONFIG to point to ${AWS_CLUSTER_NAME}..."
    
    aws eks --region $AWS_REGION update-kubeconfig --name $AWS_CLUSTER_NAME

    sleep 2
    echo $AWS_BUCKET $AWS_REGION
    velero install --use-restic --provider aws --plugins velero/velero-plugin-for-aws:v1.2.1 --bucket $AWS_BUCKET --backup-location-config region=$AWS_REGION --snapshot-location-config region=$AWS_REGION --secret-file ./aws-credentials-velero --wait

    #velero install --use-restic --provider aws --plugins velero/velero-plugin-for-aws:v1.2.1 --bucket $AWS_BUCKET --secret-file ./aws-credentials-velero --wait

    echo "Velero configured and installed"

    velero backup-location get 

    kubectl logs deployment/velero -n velero | grep error 
fi 

