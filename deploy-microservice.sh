# Creates a microservice project.

# USAGE
#   ./create_update_phoenix_project.sh [create | update]

if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in either 'create' or 'update'."
    exit 1
fi

STACK_NAME=`jq '.Parameters.StackName' template-microservice-params.json`

# Regenerate the dev params file into a format the the CloudFormation CLI expects.
python parameters_generator.py template-microservice-params.json > temp.json

aws cloudformation $1-stack \
    --stack-name $STACK_NAME \
    --template-body file://template-microservice.json \
    --capabilities CAPABILITY_NAMED_IAM

# Cleanup
rm temp.json
