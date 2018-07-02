#!/bin/bash
set -e

# Creates or updates the Microservice VPC endpoints.
#
# USAGE
#   ./deploy-vpc-endpoints.sh [create | update]

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-vpc-endpoints-params-dev.json cloudformation > temp_dev.json
python parameters_generator.py template-vpc-endpoints-params-testing.json cloudformation > temp_testing.json
python parameters_generator.py template-vpc-endpoints-params-prod.json cloudformation > temp_prod.json

# Validate the CloudFormation template before template execution.
aws cloudformation validate-template --template-body file://template-vpc-endpoints.json

# Create or update the dev VPC Endpoint.
aws cloudformation $1-stack \
    --stack-name dev-vpc-endpoints \
    --template-body file://template-vpc-endpoints.json \
    --parameters file://temp_dev.json

# Create or update the testing VPC Endpoint.
aws cloudformation $1-stack \
    --stack-name testing-vpc-endpoints \
    --template-body file://template-vpc-endpoints.json \
    --parameters file://temp_testing.json

# Create or update the prod VPC Endpoint.
aws cloudformation $1-stack \
    --stack-name prod-vpc-endpoints \
    --template-body file://template-vpc-endpoints.json \
    --parameters file://temp_prod.json

# Cleanup
rm temp_dev.json
rm temp_testing.json
rm temp_prod.json
