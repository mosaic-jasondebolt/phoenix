#!/bin/bash
set -e

# Deploys API Gateway deployments and Lambda Functions to the Dev environment.

# USAGE:
#   ./deploy-api-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-api-dev.sh create
#   ./deploy-api-dev.sh update

# Grab the current username so we can propagate to URL's, stack names, etc.
USERNAME=`echo $USER | tr . "-"` # Replace . in username with hyphen for CloudFormation naming convention.
VERSION_ID=dev_$USERNAME

# Extract JSON properties for a file into a local variable
AWS_ACCOUNT_ID=`jq -r '.Parameters.AWSAccountId' template-microservice-params.json`
AWS_REGION=`jq -r '.Parameters.AWSRegion' template-microservice-params.json`
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Replace the VERSION_ID string in the dev params file with the $VERSION_ID variable
sed "s/VERSION_ID/$VERSION_ID/g" template-api-lambda-params-dev.json > temp1.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json > temp2.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-api-lambda.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $PROJECT_NAME-dev-api-lambda-$USERNAME \
    --template-body file://template-api-lambda.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_IAM

# Cleanup
rm temp1.json
rm temp2.json
