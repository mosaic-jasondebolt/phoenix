#!/bin/bash
set -e

# Update a full Lambda + API ApiGateway deployment.

# USAGE:
#   ./deploy-api-all-dev.sh ..
#        [create |
#         update api-deploy {rest-api-id} {stage-name} |
#         update swagger-postman {rest-api-id} {stage-name}]
#
# EXAMPLES:
#   ./deploy-api-all-dev.sh create
#   ./deploy-api-all-dev.sh update api-deploy l1l5pcj1xc v0
#   ./deploy-api-all-dev.sh update swagger-postman l1l5pcj1xc v0

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(aws ssm get-parameter --name /microservice/phoenix/project-name | jq '.Parameter.Value' | sed -e s/\"//g)
DOMAIN_NAME=$(aws ssm get-parameter --name /microservice/phoenix/domain | jq '.Parameter.Value' | sed -e s/\"//g)
ENVIRONMENT=`jq -r '.Parameters.Environment' template-api-deployment-params-dev.json`
API_DEPLOYMENT_STACK_NAME=$PROJECT_NAME-api-deployment-$ENVIRONMENT

if [ $1 == "create" ]
  then
    ./deploy-lambda-dev.sh $1
    ./deploy-api-custom-domain-dev.sh $1
    ./deploy-api-dev.sh $1
    ./deploy-api-internals-dev.sh $1
    ./deploy-api-deployment-dev.sh $1
fi

API_ID=$3
VERSION=$4

# 1. Generates Swagger file from an API gateway REST API.
# 2. Generates a ~/swagger_postman.json that can be imported into Postman for testing purposes.
# 3. Opens a local browser tab with API docs.
swagger_postman() {
  aws apigateway get-export --parameters extensions='integrations' --rest-api-id $API_ID \
      --stage-name $VERSION --export-type swagger $HOME/swagger_integrations.json

  aws apigateway get-export --parameters extensions='postman' --rest-api-id $API_ID \
      --stage-name $VERSION --export-type swagger $HOME/swagger_postman.json

  spectacle ~/swagger_integrations.json --target-dir $HOME/swagger_out
  echo Open in your browser: file:///$HOME/swagger_out/index.html
  open file:///$HOME/swagger_out/index.html
}

if [ $1 == "update" ] && [ $2 == "swagger-postman" ]
  then
    swagger_postman
fi

# Deploy or redoploy an "API deployment" from the API associated with the existing rest-api-id
if [ $1 == "update" ] && [ $2 == "api-deploy" ]
  then
    ./deploy-api-dev.sh update
    ./deploy-api-internals-dev.sh update

    aws apigateway delete-base-path-mapping --domain-name $ENVIRONMENT.$DOMAIN_NAME --base-path $VERSION
    aws apigateway delete-stage --rest-api-id $API_ID --stage-name $VERSION
    aws apigateway delete-documentation-version --rest-api-id $API_ID --documentation-version $VERSION

    aws apigateway create-deployment --rest-api-id $API_ID --stage-name $VERSION
    aws apigateway create-documentation-version --rest-api-id $API_ID --stage-name $VERSION --documentation-version $VERSION
    aws apigateway create-base-path-mapping --domain-name $ENVIRONMENT.$DOMAIN_NAME --base-path $VERSION --rest-api-id $API_ID --stage $VERSION

    # The CloudFormation is super slow, hence the CLI calls above with do something similar but much faster.
    #./deploy-api-deployment-dev.sh delete
    #aws cloudformation wait stack-delete-complete --stack-name $API_DEPLOYMENT_STACK_NAME
    #./deploy-api-deployment-dev.sh create

    swagger_postman

    exit 1
fi
