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

# Convert create/update to uppercase
OP=$(echo $1 | tr '/a-z/' '/A-Z/')

# Extract JSON properties for a file into a local variable
CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-ssm-globals-macro-params.json)
ORGANIZATION_NAME=$(jq -r '.Parameters.OrganizationName' template-ssm-globals-macro-params.json)
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-ssm-globals-macro-params.json)
LAMBDA_BUCKET_NAME=$ORGANIZATION_NAME-$PROJECT_NAME-lambda
ENVIRONMENT='all'
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
CHANGE_SET_NAME=$VERSION_ID
RELEASE_ENVIRONMENTS=$(jq -r '.Parameters.ReleaseEnvironments' template-ssm-globals-macro-params.json)
RELEASE_ENVIRONMENTS_LIST=$(echo $RELEASE_ENVIRONMENTS | sed "s/,//g")

if [ $1 = "delete" ]; then
  for release_environment in $RELEASE_ENVIRONMENTS_LIST
  do
    STACK_NAME=$PROJECT_NAME-ssm-environments-$release_environment
    echo 'Deleting stack ' $STACK_NAME
    aws cloudformation delete-stack --stack-name $STACK_NAME
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
  done
  exit 0
fi

for release_environment in $RELEASE_ENVIRONMENTS_LIST
do
  # call your procedure/other scripts here below
  STACK_NAME=$PROJECT_NAME-ssm-environments-$release_environment
  echo $OP 'stack' $STACK_NAME
  # Replace the VERSION_ID string in the dev params file with the $VERSION_ID variable
  sed "s/VERSION_ID/$VERSION_ID/g" template-ssm-environments-params-$release_environment.json > temp1.json

  # Regenerate the dev params file into a format the the CloudFormation CLI expects.
  python parameters_generator.py temp1.json cloudformation > temp2.json

  # Validate the CloudFormation template before template execution.
  aws cloudformation validate-template --template-body file://template-ssm-environments.json

  aws cloudformation create-change-set --stack-name $STACK_NAME \
      --change-set-name $CHANGE_SET_NAME \
      --template-body file://template-ssm-environments.json \
      --parameters file://temp2.json \
      --change-set-type $OP \
      --capabilities CAPABILITY_IAM \
      --role-arn $CLOUDFORMATION_ROLE

  aws cloudformation wait change-set-create-complete \
      --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME

  aws cloudformation execute-change-set --stack-name $STACK_NAME \
      --change-set-name $CHANGE_SET_NAME

  # Cleanup
  rm temp1.json
  rm temp2.json
done
