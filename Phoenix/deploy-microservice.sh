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

# Replace any phoenix SSM parameter keys if they exist. Useful for overwriting files after Phoenix repo merges.
PROJECT_NAME=`jq -r '.Parameters.ProjectName' ssm-microservice-params.json`
PHOENIX_PREFIX='phoenix'

if [ -d "builds" ]; then
  echo deleting builds dir
  rm -rf builds
fi
python search_and_replace.py . /microservice/$PHOENIX_PREFIX/global/ /microservice/$PROJECT_NAME/global/

# Extract JSON properties for a file into a local variable
CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' ssm-microservice-params.json)
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
STACK_NAME=$PROJECT_NAME-microservice
VERSION_ID='microservice'-'v0' # Increment this version whenever you make a change to a Lambda function to force code update
MICROSERVICE_BUCKET_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/bucket-name | jq '.Parameter.Value' | sed -e s/\"//g)
LAMBDA_BUCKET_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/lambda-bucket-name | jq '.Parameter.Value' | sed -e s/\"//g)

# Generate the MICROSERVICE bucket if it doesn't already exist
aws s3 mb s3://$MICROSERVICE_BUCKET_NAME
aws s3 sync . s3://$MICROSERVICE_BUCKET_NAME/cloudformation --exclude "*" --include "template-*.json" --delete
aws s3 mb s3://$LAMBDA_BUCKET_NAME

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-microservice.json

# Replace the VERSION_ID string in the dev params file with the $VERSION_ID variable
sed "s/VERSION_ID/$VERSION_ID/g" template-microservice-params.json > temp1.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json cloudformation > temp2.json

aws cloudformation $1-stack \
    --stack-name $STACK_NAME \
    --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-microservice.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn $CLOUDFORMATION_ROLE

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

if [[ $1 == 'create' ]]; then
  aws cloudformation update-termination-protection --enable-termination-protection --stack-name $STACK_NAME
fi

# Cleanup
rm temp1.json
rm temp2.json
