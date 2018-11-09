#!/bin/bash
set -e

# Saves a GitHub access token to SSM parameter store for the pipeline webhook.
# You must generate an access token within GitHub and pass it to this script.
#
# When creating the webhook in GitHub, give it a name like "{YourProjectName}PipelineWebhook"
# and give in the "repo" and "admin:repo_hook" scopes. Also be sure to select "Enable SSO"
# and then "Authorize" else the token will not work.
#
# USAGE
#   ./deploy-ssm-github-token.sh {Github Token}

# Check for valid arguments
if [ $# -ne 1 ]
  then
    echo "Incorrect number of arguments supplied. Pass in a Githab access token"
    exit 1
fi

# Extract JSON properties for a file into a local variable
PROJECT_NAME=$(jq -r '.Parameters.ProjectName' template-ssm-globals-macro-params.json)

aws ssm put-parameter \
  --name /microservice/$PROJECT_NAME/global/github/tokens/pipeline \
  --description 'GitHub token used by the main pipeline for this project' \
  --type 'String' \
  --overwrite \
  --value $1
