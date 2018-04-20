#!/bin/bash
set -e

# Creates or updates the database layer.
#
# In this stack, the database passwords are automatically generated in Lambda,
# encrypted, and stored in AWS SSM Parameter Store for later retrieval.
#
# The password in returned to the CloudFormation stack and used in the MasterUserPassword
# parameter. All authored EC2 instances, ECS containers, etc. can then use the project
# KMS Key found in the microservice stack to decrypt the MasterPassword and
# initiate a database connection
#
# USAGE
#   ./deploy-database.sh [create | update] [dev | testing | prod]

# Check for valid arguments
if [ $# -ne 2 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update' and either 'dev', 'testing', 'prod'."
    exit 1
fi

ENVIRONMENT=$2
LAMBDA_BUCKET_NAME=`jq -r '.Parameters.LambdaBucketName' template-database-params-$ENVIRONMENT.json`

# When this script is run locally, use the user's username within the version ID.
USERNAME=`echo $USER | tr . "-"` # Replace . in username with hyphen for CloudFormation naming convention.
VERSION_ID=$ENVIRONMENT'_'$USERNAME

VERSION=`jq -r '.Parameters.Version' template-database-params-$ENVIRONMENT.json`

# Upload the Lambda function
mkdir -p builds/password_generator
cp -rf lambda/password_generator/* builds/password_generator/
cd builds/password_generator/
pip install -r requirements.txt -t .
zip -r lambda_function.zip ./*
aws s3 cp lambda_function.zip s3://$LAMBDA_BUCKET_NAME/$VERSION_ID/password_generator/
cd ../../
rm -rf builds

sed "s/VERSION_ID/$VERSION_ID/g" template-database-params-$ENVIRONMENT.json > temp1.json
# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json > temp2.json

aws cloudformation validate-template --template-body file://template-database.json

# Create or update the dev VPC.
aws cloudformation $1-stack \
    --stack-name phoenix-database-$ENVIRONMENT \
    --template-body file://template-database.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_IAM

# Cleanup
rm temp1.json
rm temp2.json
