#!/bin/bash
set -e

# Deploys API documentation to dev S3 static websites.

# USAGE:
#   ./deploy-api-documentations-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-api-documentations-dev.sh create
#   ./deploy-api-documentations-dev.sh update

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/project-name | jq '.Parameter.Value' | sed -e s/\"//g)

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

listOfVersions='v0'
for docVersion in $listOfVersions
do
  ENVIRONMENT=$(jq -r '.Parameters.Environment' template-api-documentation-$docVersion-params-dev.json)
  STACK_NAME=$PROJECT_NAME-api-documentation-$docVersion-$ENVIRONMENT

  # Regenerate the dev params file into a format the the CloudFormation CLI expects.
  python parameters_generator.py template-api-documentation-$docVersion-params-dev.json cloudformation > temp1.json

  # Validate the CloudFormation template before template execution.
  aws cloudformation validate-template --template-body file://template-api-documentation.json

  # Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
  aws cloudformation $1-stack --stack-name $STACK_NAME \
      --template-body file://template-api-documentation.json \
      --parameters file://temp1.json \
      --capabilities CAPABILITY_IAM

  aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME
done

# Cleanup
rm temp1.json
