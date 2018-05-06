#!/bin/bash
set -e

# Checks out a new git branch and create a review code pipeline on the branch.

# USAGE:
#   ./deploy-git-branch-and-pipeline.sh {environment_name} {branch_name}
#
# EXAMPLES:
#   ./deploy-git-branch-and-pipeline.sh devjason fix-all-the-things

# Create a new git branch
git checkout -b $1

# Generate the param files
python generate_dev_params.py $0 $1

# Create the Cloudformation stack
/bin/bash deploy-code-pipeline-review-dev.sh create

git push origin
