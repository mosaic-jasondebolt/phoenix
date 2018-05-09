#!/bin/bash
set -e

# Creates a microservice project.
#
# USAGE
#   ./deploy-microservice.sh [create | update]

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Extract JSON properties for a file into a local variable
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`
MICROSERVICE_STACK_NAME=$PROJECT_NAME-microservice
MICROSERVICE_BUCKET_NAME=`jq -r '.Parameters.MicroserviceBucketName' template-microservice-params.json | sed 's/PROJECT_NAME/'$PROJECT_NAME'/g'`
VERSION_ID=`date +"%Y-%m-%d-%H%M%S"`

# Generate the MICROSERVICE bucket if it doesn't already exist
aws s3 mb s3://$MICROSERVICE_BUCKET_NAME
aws s3 sync . s3://$MICROSERVICE_BUCKET_NAME/cloudformation --exclude "*" --include "template-*.json" --delete
aws s3 sync ./lambda s3://$MICROSERVICE_BUCKET_NAME/lambda/ --include "*" --delete

# Upload the Lambda functions
listOfLambdaFunctions='dev_access_branch'
for functionName in $listOfLambdaFunctions
do
  mkdir -p builds/$functionName
  cp -rf lambda/$functionName/* builds/$functionName/
  cd builds/$functionName/
  pip install -r requirements.txt -t .
  zip -r lambda_function.zip ./*
  aws s3 cp lambda_function.zip s3://$MICROSERVICE_BUCKET_NAME/lambda/$VERSION_ID/$functionName/
  cd ../../
  rm -rf builds
done

# Replace the IMAGE_TAG string in the dev params file with the $IMAGE_TAG variable
sed "s/VERSION_ID/$VERSION_ID/g" template-microservice-params.json > temp1.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json cloudformation > temp2.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-microservice.json

aws cloudformation $1-stack \
    --stack-name $MICROSERVICE_STACK_NAME \
    --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-microservice.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_NAMED_IAM

# Cleanup
rm temp1.json
rm temp2.json
