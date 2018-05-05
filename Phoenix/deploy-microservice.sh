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

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-microservice-params.json cloudformation > temp.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-microservice.json

aws cloudformation $1-stack \
    --stack-name $MICROSERVICE_STACK_NAME \
    --template-body file://template-microservice.json \
    --parameters file://temp.json \
    --capabilities CAPABILITY_NAMED_IAM

# Cleanup
rm temp.json
