#!/bin/bash
set -e

# Deploys the 'API Internals' CloudFormation stack for fine-grained API tuning.
# This is API configuration that is too verbose to fit into CloudFormation templates.

# USAGE:
#   ./deploy-api-internals-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-api-internals-dev.sh create
#   ./deploy-api-internals-dev.sh update

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-params-dev.json`
LAMBDA_BUCKET_NAME=$(aws ssm get-parameter --name /microservice/phoenix/global/lambda-bucket-name | jq '.Parameter.Value' | sed -e s/\"//g)
# Allow developers to name the environment whatever they want, supporting multiple dev environments.
VERSION_ID=$ENVIRONMENT-`date '+%Y-%m-%d-%H%M%S'`

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

listOfLambdaFunctions='api_internals'
for functionName in $listOfLambdaFunctions
do
  mkdir -p builds/$functionName
  cp -rf lambda/$functionName/* builds/$functionName/
  cd builds/$functionName/
  pip install -r requirements.txt -t .
  zip -r lambda_function.zip ./*
  aws s3 cp lambda_function.zip s3://$LAMBDA_BUCKET_NAME/$VERSION_ID/$functionName/
  cd ../../
  rm -rf builds
done

# Replace the VERSION_ID string in the dev params file with the $VERSION_ID variable
sed "s/VERSION_ID/$VERSION_ID/g" template-api-internals-params-dev.json > temp1.json

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json cloudformation > temp2.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-api-internals.json

STACK_NAME=$PROJECT_NAME-api-internals-$ENVIRONMENT

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $STACK_NAME \
    --template-body file://template-api-internals.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_IAM

aws cloudformation wait stack-$1-complete --stack-name $STACK_NAME


# Cleanup
rm temp1.json
rm temp2.json
