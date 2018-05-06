#!/bin/bash
set -e

# Checks out a new git branch and create a review code pipeline on the branch.

# USAGE:
#   ./deploy-git-branch-and-pipeline.sh {environment_name} {branch_name}
#
# EXAMPLES:
#   ./deploy-git-branch-and-pipeline.sh devjason fix-all-the-things

ENVIRONMENT_NAME=$1
BRANCH_NAME=$2

# Create a new git branch
git checkout -b $BRANCH_NAME

# Generate the param files
python generate_dev_params.py $ENVIRONMENT_NAME $BRANCH_NAME

# Create the Cloudformation stack
/bin/bash deploy-code-pipeline-review-dev.sh create

git push origin
