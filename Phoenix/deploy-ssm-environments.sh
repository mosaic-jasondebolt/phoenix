#!/bin/bash
set -e

# Creates, updates, or deletes environment specific SSM parameters.
#
# USAGE
#   ./deploy-ssm-environments.sh [create | update | delete]

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create', 'update' or 'delete'."
    exit 1
fi

# Extract JSON properties for a file into a local variable
CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-ssm-globals-macro-params.json)
ORGANIZATION_NAME=$(jq -r '.Parameters.OrganizationName' template-ssm-globals-macro-params.json)
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-ssm-globals-macro-params.json)
LAMBDA_BUCKET_NAME=$ORGANIZATION_NAME-$PROJECT_NAME-lambda
ENVIRONMENT='all'
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
ENVIRONMENT_PARAM_FILES=$(ls template-ssm-environments-params-*)

if [ $1 = "delete" ]; then
  for filename in $ENVIRONMENT_PARAM_FILES
  do
    ENVIRONMENT=$(jq -r '.Parameters.Environment' $filename)
    STACK_NAME=$PROJECT_NAME-ssm-environments-$ENVIRONMENT
    echo 'Deleting stack ' $STACK_NAME
    aws cloudformation delete-stack --stack-name $STACK_NAME
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
  done
  exit 0
fi

for filename in $ENVIRONMENT_PARAM_FILES
do
  # call your procedure/other scripts here below
  ENVIRONMENT=$(jq -r '.Parameters.Environment' $filename)
  STACK_NAME=$PROJECT_NAME-ssm-environments-$ENVIRONMENT
  # Replace the VERSION_ID string in the dev params file with the $VERSION_ID variable
  sed "s/VERSION_ID/$VERSION_ID/g" $filename > temp1.json

  # Regenerate the dev params file into a format the the CloudFormation CLI expects.
  python parameters_generator.py temp1.json cloudformation > temp2.json

  # Validate the CloudFormation template before template execution.
  aws cloudformation validate-template --template-body file://template-ssm-environments.json

  aws cloudformation $1-stack \
      --stack-name $STACK_NAME \
      --template-body file://template-ssm-environments.json \
      --parameters file://temp2.json \
      --capabilities CAPABILITY_IAM \
      --role-arn $CLOUDFORMATION_ROLE

  aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME

  # Cleanup
  rm temp1.json
  rm temp2.json
done
