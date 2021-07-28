# AWS ACCESS KEY AND SECRET ( this is used for connecting to S3, so it need the appropriate IAM permissions to WRITE to an S3 bucket)
echo "
[default]
aws_access_key_id=
aws_secret_access_key=
" > ./pocs/via-s3/source/secrets/credentials

echo '
{
  "type": "service_account",
  "project_id": "",
  "private_key_id": "",
  "private_key": "",
  "client_email": "",
  "client_id": "",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": ""
}
' | tee ./pocs/via-s3/dest/secrets/service-account.json ./pocs/p2p/dest/secrets/service-account.json


export SRC_OIDC_TOKEN=$(k8s-okta oidc-token --client-id 0oa54lqa1zwIWea3P2p7 | jq -r .status.token)


