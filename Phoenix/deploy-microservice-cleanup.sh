#!/bin/bash
set -e

# Creates a microservice cleanup resources.
#
# USAGE
#   ./deploy-microservice-cleanup.sh [create | update]

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Extract JSON properties for a file into a local variable
CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-macro-params.json)
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
STACK_NAME=$PROJECT_NAME-microservice-cleanup
MICROSERVICE_BUCKET_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/bucket-name | jq '.Parameter.Value' | sed -e s/\"//g)

aws s3 sync . s3://$MICROSERVICE_BUCKET_NAME/cloudformation --exclude "*" --include "template-microservice-cleanup.json" --delete

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-microservice-cleanup.json

aws cloudformation $1-stack \
    --stack-name $STACK_NAME \
    --template-url https://s3.amazonaws.com/$MICROSERVICE_BUCKET_NAME/cloudformation/template-microservice-cleanup.json \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn $CLOUDFORMATION_ROLE

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME
