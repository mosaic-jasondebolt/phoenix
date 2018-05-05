#!/bin/bash
set -e

# Deploys a dev Code Pipeline.

# USAGE:
#   ./deploy-code-pipeline-dev.sh [create | update]
#
# EXAMPLES:
#   ./deploy-code-pipeline-dev.sh create
#   ./deploy-code-pipeline-dev.sh update

# Extract JSON properties for a file into a local variable
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`
ENVIRONMENT=`jq -r '.Parameters.Environment' template-code-pipeline-params-dev.json`
BRANCH_NAME=`jq -r '.Parameters.BranchName' template-code-pipeline-params-dev.json`
# Allow developers to name the environment whatever they want, supporting multiple dev environments.

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-code-pipeline-params-dev.json cloudformation > temp1.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-code-pipeline.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $PROJECT_NAME-code-pipeline-$ENVIRONMENT-$BRANCH_NAME \
    --template-body file://template-code-pipeline.json \
    --parameters file://temp1.json \
    --capabilities CAPABILITY_IAM

# Cleanup
rm temp1.json
