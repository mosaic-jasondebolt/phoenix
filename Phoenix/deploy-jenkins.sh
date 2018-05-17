#!/bin/bash
set -e

# Deploys a Jenkins instance.

# USAGE:
#   ./deploy-jenkins.sh [create | update]
#
# EXAMPLES:
#   ./deploy-jenkins.sh create
#   ./deploy-jenkins.sh update [version_id]
#
#   Where,
#     version_id is the number at the end of the stack name.

# Extract JSON properties for a file into a local variable
PROJECT_NAME=`jq -r '.Parameters.ProjectName' template-microservice-params.json`
DOMAIN=`jq -r '.Parameters.Domain' template-microservice-params.json`
DNS_PREFIX=`jq -r '.Parameters.DnsPrefix' template-jenkins-params.json`

# Check for valid arguments
if [ $# -ne 1 ];
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Replace the VERSION_ID string in the params file with the $VERSION_ID variable
sed "s/DOMAIN/$DOMAIN/g" template-jenkins-params.json > temp1.json

# Regenerate the params file into a format the the CloudFormation CLI expects.
python parameters_generator.py temp1.json cloudformation > temp2.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-jenkins.json

# Create or update the CloudFormation stack with deploys your docker service to the Dev cluster.
aws cloudformation $1-stack --stack-name $PROJECT_NAME-jenkins-$DNS_PREFIX \
    --template-body file://template-jenkins.json \
    --parameters file://temp2.json \
    --capabilities CAPABILITY_IAM

# Cleanup
rm temp1.json
rm temp2.json
