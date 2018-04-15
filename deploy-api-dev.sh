#!/bin/bash
set -e

# Uploads/Deploys the Phoenix API and all supporting backend and database resources.

# USAGE:
#   ./upload_function.sh {dev|staging|prod}

LAMBDA_S3_LOCATION="s3://mosaic-phoenix-cfn/lambdas/"
PROJECT_NAME=`jq '.Parameters.ProjectName' template-microservice-params.json`

aws s3 sync --delete backend/lambdas/ s3://mosaic-phoenix-cfn/lambdas/

aws cloudformation validate-template --template-body file://api.json

aws cloudformation deploy --stack-name phoenix-api-$1 \
  --template-file api.json \
  --parameter-overrides Environment=$1 \
                        ProjectName=$PROJECT_NAME \
                        LambdaS3Location=$LAMBDA_S3_LOCATION \
  --capabilities CAPABILITY_IAM
