""" Handles CodeBuild jobs executing in the context of a release.

USAGE:
  python release_codebuild.py [build | unit-test | lint]

  As long as you have the environment variables set as specified in the
  initializer, you can run this script either locally or on AWS CodeBuild.

  Within AWS CodeBuild, these environment variables will automatically be set
  from the 'template-release-environment-pipeline.json' CloudFormation stack, which
  is created by a Lambda function that is invoked by a GitLab webhook
  for branch push events.

  This script does the following:
    1) Persists a gitlab-release.json file that is passed to a Lambda function.
"""

__author__ = "Jason DeBolt (jasondebolt@gmail.com)"

import os
import urllib
from urllib.parse import quote
import sys
import json
import requests

# These env variables are passed in via CloudFormation
PIPELINE_NAME = os.environ.get('PIPELINE_NAME')
GITLAB_PROJECT_ID = os.environ.get('GITLAB_PROJECT_ID')
RELEASE_ENVIRONMENT = os.environ.get('RELEASE_ENVIRONMENT')
REPO_NAME = os.environ.get('REPO_NAME')
SOURCE_BRANCH = os.environ.get('SOURCE_BRANCH')

# These env variables are sometimes made avaialable in codebuild
GITLAB_ACCESS_TOKEN = os.environ.get('GITLAB_ACCESS_TOKEN')
GITLAB_UNIT_TEST_ACCESS_TOKEN = os.environ.get('GITLAB_UNIT_TEST_ACCESS_TOKEN')
GITLAB_LINT_ACCESS_TOKEN = os.environ.get('GITLAB_LINT_ACCESS_TOKEN')
GIT_URL = os.environ.get('GIT_URL', '')

# These env variables are always avaialable in AWS CodeBuild
CODE_BUILD_ARN = os.environ.get('CODEBUILD_BUILD_ARN')
CODE_BUILD_REGION = os.environ.get('AWS_DEFAULT_REGION')
CODEBUILD_BUILD_SUCCEEDING = int(os.environ.get('CODEBUILD_BUILD_SUCCEEDING', 0))
CODEBUILD_RESOLVED_SOURCE_VERSION = os.environ.get('CODEBUILD_RESOLVED_SOURCE_VERSION')

# Gitlab vars
GITLAB_API_URL = os.path.join(GIT_URL, 'api/v4/projects')

class RequestSender(object):
    def __init__(self, token):
        self.token = token
    def send_request(self, url):
        print('Posting to {0}'.format(url))
        headers = {'Private-Token': self.token}
        response = requests.post(url, headers=headers)
        print(response)

def generate_lambda_gitlab_release_config():
    print("Saving gitlab-release.json file for the LambdaPostRelease lambda function to pick up.")
    gitlab_obj = {
      'RepoName': REPO_NAME,
      'SourceBranch': SOURCE_BRANCH,
      'ReleaseEnvironment': RELEASE_ENVIRONMENT,
      'SourceVersion': CODEBUILD_RESOLVED_SOURCE_VERSION,
      'ProjectId': GITLAB_PROJECT_ID
    }
    gitlab_lambda_config_file = open('gitlab-release.json', 'w')
    gitlab_lambda_config_file.write(json.dumps(gitlab_obj, indent=2))

def _parse_json(path):
    result = open(os.path.join(sys.path[0], path), 'rb').read()
    try:
        return json.loads(result)
    except json.decoder.JSONDecodeError as e:
        print('\nYour JSON is not valid! Did you check trailing commas??\n')
        raise(e)

def onBuildJobCompletion():
    generate_lambda_gitlab_release_config()

def onUnitTestJobCompletion():
    # TODO (jasondebolt): Implement some post-unit-test action here.
    pass

def onLintJobCompletion():
    # TODO (jasondebolt): Implement some post-lint action here.
    pass

if __name__ == '__main__':
    # The gitlab-release.json file is expected by the Lambda function that runs at the end of the release pipeline.
    # Creating an empty gitlab-release.json file here for cases where this is a non-release request related build.
    # If this file is not created, the buildspec.yml file cause the 'build' CodeBuild job to fail since it is explicitly listed as an artifact.
    # See the 'generate_lambda_gitlab_release_config()' function above for the real gitlab-release.json file that will overwrite this file if this is a release build.
    gitlab_lambda_config_file = open('gitlab-release.json', 'w')
    gitlab_lambda_config_file.write('')

    if len(sys.argv) != 2:
        print('You must pass in build, unit-test, or lint as an argument')
        sys.exit(0)
    # Any of the three following conditions may be met if this is a non-release request build.
    if not GITLAB_PROJECT_ID:
        print('GITLAB_PROJECT_ID environment variable not set. This might be a non release build.')
        sys.exit(0)
    if not RELEASE_ENVIRONMENT:
        print('RELEASE_ENVIRONMENT environment variable not set. This might be a non release build.')
        sys.exit(0)
    if not REPO_NAME:
        print('REPO_NAME environment variable not set. This might be a non release build.')
        sys.exit(0)
    if not SOURCE_BRANCH:
        print('SOURCE_BRANCH environment variable not set. This might be a non release build.')
        sys.exit(0)
    if not GIT_URL:
        print('GIT_URL environment variable not set. This might be a non release build.')
        sys.exit(0)

    arg = sys.argv[1]

    if arg == 'build':
        if not GITLAB_ACCESS_TOKEN:
            print('No GITLAB_ACCESS_TOKEN environment variable has been set!')
            sys.exit(0)
        if not PIPELINE_NAME:
            print('PIPELINE_NAME environment variable not set. This might be a non release build.')
            sys.exit(0)
        print('Running onBuildJobCompletion')
        onBuildJobCompletion()
    elif arg == 'unit-test':
        if not GITLAB_UNIT_TEST_ACCESS_TOKEN:
            print('No GITLAB_UNIT_TEST_ACCESS_TOKEN environment variable has been set!')
            sys.exit(0)
        print('Running onUnitTestJobCompletion')
        onUnitTestJobCompletion()
    elif arg == 'lint':
        if not GITLAB_LINT_ACCESS_TOKEN:
            print('No GITLAB_LINT_ACCESS_TOKEN environment variable has been set!')
            sys.exit(0)
        print('Running onLintJobCompletion')
        onLintJobCompletion()
    else:
        print('Unknown argument: {0}'.format(arg))
