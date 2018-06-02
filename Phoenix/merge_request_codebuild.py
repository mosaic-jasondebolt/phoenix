""" Handles CodeBuild jobs executing in the context of a GitLab Merge Request

USAGE:
  python2.7 merge_request_codebuild.py

  This script must be run using Python2.7 as that is the version of Python
  that is being used in our AWS CodeBuild environment.

  As long as you have the environment variables set as specified in the
  'isMergeRequest' function, you can run this script either locally
  or on AWS CodeBuild.

  Within AWS CodeBuild, these environment variables will automatically be set
  from the 'template-merge-request-pipeline.json' CloudFormation stack, which
  is created by a Lambda function that is invoked by a GitLab webhook
  for merge request events.

  This script does the following:
    1) Notifies GitLab of the status of AWS CodeBuild jobs.
    2) Generates an ECS parameter template specifically for spinning up
       a dev ECS instance used during code review.
"""

__author__ = "Jason DeBolt (jasondebolt@gmail.com)"

import os
import urllib
import sys
import json
import requests

def isMergeRequest():
    # Notify gitlab of successful build status if these environment variables are present
    # Some of these env variables will be made available to the CodeBuild job via
    # CloudFormation environment variable injection
    return (
        os.environ.get('GITLAB_ACCESS_TOKEN') and
        os.environ.get('PROJECT_NAME') and
        os.environ.get('PIPELINE_NAME') and
        os.environ.get('GITLAB_PROJECT_ID') and
        os.environ.get('MERGE_REQUEST_INTERNAL_ID') # This env variable is inject via cloudformation into the CodeBuild job
    )

def _get_code_build_url(region, build_name, build_id):
    return (
        'https://console.aws.amazon.com/codebuild/home?region={region}'
        '#/builds/{build_name}:{build_id}/view/new'
        ).format(
            region=region, build_name=build_name, build_id=build_id)

def _get_code_build_body(code_build_url, build_name, source_version):
    body = (
        '<a href="{code_build_url}">{build_name}</a> &nbsp; &nbsp; :thumbsup: '
        '@ commit {source_version}').format(
            code_build_url=code_build_url, build_name=build_name,
            source_version=source_version)
    return urllib.quote(body)

def _get_gitlab_url(project_id, merge_request_id, code_build_body):
    return (
        'https://gitlab.intranet.solarmosaic.com/api/v4/projects/{project_id}/'
        'merge_requests/{merge_request_id}/notes?body={body}').format(
            project_id=project_id, merge_request_id=merge_request_id,
            body=code_build_body)

def _notify_gitlab(code_build_url, gitlab_url):
    print("Notifying gitlab")
    headers = {'Private-Token': os.environ.get('GITLAB_ACCESS_TOKEN')}
    response = requests.post(gitlab_url, headers=headers)
    print(code_build_url)
    print(response)

def _generate_dev_ecs_params():
    file_path = os.path.join(
        os.environ.get('CODEBUILD_SRC_DIR'), 't-ecs-params-testing.json'
    )
    ecs_params = _parse_json(file_path)
    print(json.dumps(ecs_params, indent=2))

    # Swap out the testing environment for a new merge request specific environment
    ecs_params['Parameters']['Environment'] = os.environ.get('PIPELINE_NAME')

    ecs_params_file = open('t-ecs-params-testing.json', 'w')
    ecs_params_file.write(json.dumps(ecs_params, indent=2))

def _parse_json(path):
    result = open(os.path.join(sys.path[0], path), 'rb').read()
    try:
        return json.loads(result)
    except json.decoder.JSONDecodeError as e:
        print('\nYour JSON is not valid! Did you check trailing commas??\n')
        raise(e)

def main():
    if isMergeRequest():
        gitlab_token = os.environ.get('GITLAB_ACCESS_TOKEN')
        project_id = os.environ.get('PROJECT_NAME')
        pipeline_name = os.environ.get('PIPELINE_NAME')
        gitlab_project_id = os.environ.get('GITLAB_PROJECT_ID')
        merge_request_id = os.environ.get('MERGE_REQUEST_INTERNAL_ID')

        code_build_arn = os.environ.get('CODEBUILD_BUILD_ARN')
        code_build_region = os.environ.get('AWS_DEFAULT_REGION')
        source_version = os.environ.get('CODEBUILD_RESOLVED_SOURCE_VERSION')
        build_name = code_build_arn.split(':')[-2].split('/')[1]
        build_id = code_build_arn.split(':')[-1]

        code_build_url = _get_code_build_url(code_build_region, build_name, build_id)
        code_build_body = _get_code_build_body(code_build_url, build_name, source_version)
        gitlab_url = _get_gitlab_url(project_id, merge_request_id, code_build_body)

        _notify_gitlab(code_build_url, gitlab_url)
        _generate_dev_ecs_params()
    else:
        print('not all environment variable for gitlab notification are present')


if __name__ == '__main__':
    main()
