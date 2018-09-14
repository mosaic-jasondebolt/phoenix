#!/bin/bash
set -e

# Deploys API documentation to dev S3 static websites.

# USAGE:
#   ./deploy-api-documentations-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-api-documentations-dev.sh create
#   ./deploy-api-documentations-dev.sh update

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Convert create/update to uppercase
OP=$(echo $1 | tr '/a-z/' '/A-Z/')

CLOUDFORMATION_ROLE=$(jq -r '.Parameters.IAMRole' template-macro-params.json)
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-macro-params.json)

listOfVersions='v0'
for docVersion in $listOfVersions
do
  ENVIRONMENT=$(jq -r '.Parameters.Environment' template-api-documentation-$docVersion-params-dev.json)
  STACK_NAME=$PROJECT_NAME-api-documentation-$docVersion-$ENVIRONMENT
  ENVIRONMENT='all'
  VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`
  CHANGE_SET_NAME=$VERSION_ID

  # Regenerate the dev params file into a format the the CloudFormation CLI expects.
  python parameters_generator.py template-api-documentation-$docVersion-params-dev.json cloudformation > temp1.json

  # Validate the CloudFormation template before template execution.
  aws cloudformation validate-template --template-body file://template-api-documentation.json

  aws cloudformation create-change-set --stack-name $STACK_NAME \
      --change-set-name $CHANGE_SET_NAME \
      --template-body file://template-api-documentation.json \
      --parameters file://temp1.json \
      --change-set-type $OP \
      --capabilities CAPABILITY_IAM \
      --role-arn $CLOUDFORMATION_ROLE

  aws cloudformation wait change-set-create-complete \
      --change-set-name $CHANGE_SET_NAME --stack-name $STACK_NAME

  # Let's automatically execute the change-set for now
  aws cloudformation execute-change-set --stack-name $STACK_NAME \
      --change-set-name $CHANGE_SET_NAME

  aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME
done

# Cleanup
rm temp1.json
