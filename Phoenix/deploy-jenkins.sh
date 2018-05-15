#!/bin/bash
set -e

# Deploys a Jenkins instance.

# USAGE:
#   ./deploy-jenkins.sh [create | update]
#
# EXAMPLES:
#   ./deploy-jenkins.sh create
#   ./deploy-jenkins.sh update

# Extract JSON properties for a file into a local variable
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`
DOMAIN=`jq -r '.Parameters.Domain' template-microservice-params.json`
VERSION_ID=`echo $((1 + RANDOM % 10000))`

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Replace the VERSION_ID string in the params file with the $VERSION_ID variable
sed "s/VERSION_ID/$VERSION_ID/g" template-jenkins-params.json > temp1.json
sed "s/DOMAIN/$DOMAIN/g" temp1.json > temp2.json

# Regenerate the params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp2.json cloudformation > temp3.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-jenkins.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $PROJECT_NAME-jenkins-$VERSION_ID \
    --template-body file://template-jenkins.json \
    --parameters file://temp3.json \
    --capabilities CAPABILITY_IAM

# Cleanup
rm temp1.json
rm temp2.json
rm temp3.json
