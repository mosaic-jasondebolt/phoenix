import os
import re
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse

# Handles GitLab push events for releases.

# For the push-events webhook example JSON body:
# https://docs.gitlab.com/ee/user/project/integrations/webhooks.html#push-events

cloudformation_client = boto3.client('cloudformation')
ssm_client = boto3.client('ssm')

class JSONObject:
  def __init__(self, dict):
      vars(self).update(dict)

def get_microservice_bucket_name():
    response = ssm_client.get_parameter(
        Name='/microservice/{0}/global/bucket-name'.format(os.environ['PROJECT_NAME']),
        WithDecryption=False
    )
    return response['Parameter']['Value']

def get_release_environments():
    response = ssm_client.get_parameter(
        Name='/microservice/{0}/global/release-environments'.format(os.environ['PROJECT_NAME']),
        WithDecryption=False
    )
    result = response['Parameter']['Value']
    return [val.strip() for val in result.split(',')]  # ['staging', 'qa', ...]

def create_or_update_stack(create, stack_name, template_url, parameters, project_id):
    if create:
        response = cloudformation_client.create_stack(
          StackName=stack_name,
          TemplateURL=template_url,
          Parameters=parameters,
          Capabilities=['CAPABILITY_IAM']
        )
    else:
        response = cloudformation_client.update_stack(
          StackName=stack_name,
          TemplateURL=template_url,
          Parameters=parameters,
          Capabilities=['CAPABILITY_IAM']
        )

def delete_stack_if_exists(stack_name):
    # Idempotent way to delete a CloudFormation stack.
    try:
      print('Attempting to delete stack {0}'.format(stack_name))
      response = cloudformation_client.delete_stack(StackName=stack_name)
      return response
    except Exception as e:
      print('Error: {0}'.format(e))
      print('Stack {0} may not exist. Skipping delete.'.format(stack_name))

def lambda_handler(event, context):
    print(event)
    json_obj = json.dumps(event, indent=4)
    print(json_obj)
    obj = json.loads(json_obj, object_hook=JSONObject)
    if obj.object_kind != 'push':
      raise Exception('Object is not a push! object is of type' + obj.object_kind)

    path_with_namespace = obj.project.path_with_namespace               # namespace/reponame
    path_with_namespace_dashes = path_with_namespace.replace('/', '-')  # namespace-reponame
    repo_name = path_with_namespace.split('/')[-1]                      # reponame
    project_id = str(obj.project.id)        # The numeric ID that identifies the GitLab project

    is_create_branch_push_event = obj.before == '0000000000000000000000000000000000000000'
    is_delete_branch_push_event = obj.after == '0000000000000000000000000000000000000000'
    print('is_create_branch_push_event: ', is_create_branch_push_event)
    print('is_delete_branch_push_event: ', is_delete_branch_push_event)

    source_branch = obj.ref.split('/')[-1]

    is_release_branch = bool(re.match('release-\d{8}$', source_branch))
    print('is_release_branch: ', is_release_branch)
    if not is_release_branch:
        return  # We only care about release branches.

    release_environments = get_release_environments()

    for release_environment in release_environments:
        stack_name = '{repo_name}-{release_environment}-{source_branch}'.format(
          repo_name=repo_name,
          release_environment=release_environment,
          source_branch=source_branch.replace('_', '-')
        )

        template_name = 'template-release-environment-pipeline.json'
        template_url = 'https://s3.amazonaws.com/{0}/cloudformation/{1}'.format(
            get_microservice_bucket_name(), template_name)

        parameters=[
          {'ParameterKey': 'ProjectName', 'ParameterValue': os.environ['PROJECT_NAME']},
          {'ParameterKey': 'ProjectDescription', 'ParameterValue': os.environ['PROJECT_DESCRIPTION']},
          {'ParameterKey': 'CodePipelineBucketName', 'ParameterValue': os.environ['CODE_PIPELINE_BUCKET_NAME']},
          {'ParameterKey': 'CodeBuildDockerImage', 'ParameterValue': os.environ['CODE_BUILD_DOCKER_IMAGE']},
          {'ParameterKey': 'CodeBuildServiceRoleArn', 'ParameterValue': os.environ['CODE_BUILD_SERVICE_ROLE_ARN']},
          {'ParameterKey': 'CodePipelineServiceRoleArn', 'ParameterValue': os.environ['CODE_PIPELINE_SERVICE_ROLE_ARN']},
          {'ParameterKey': 'LambdaBucketName', 'ParameterValue': os.environ['LAMBDA_BUCKET_NAME']},
          {'ParameterKey': 'PipelineName', 'ParameterValue': stack_name},
          {'ParameterKey': 'RepoName', 'ParameterValue': repo_name},
          {'ParameterKey': 'GitlabProjectId', 'ParameterValue': project_id},
          {'ParameterKey': 'SourceBranch', 'ParameterValue': source_branch},
          {'ParameterKey': 'ReleaseEnvironment', 'ParameterValue': release_environment},
          {'ParameterKey': 'IAMRole', 'ParameterValue': os.environ['IAM_ROLE']}
        ]

        if is_delete_branch_push_event:
            print('Deleting Pipeline Stack')
            # Delete the pipeline stack
            response = delete_stack_if_exists(stack_name)
            print(response)
        else:
            print('Creating or Updating stack')
            print('Attempting to create stack')
            try:
                create_or_update_stack(
                    create=True, stack_name=stack_name, template_url=template_url,
                    parameters=parameters, project_id=project_id)
            except Exception as e:
                print('Stack may have already been created, and that is OK.')
                print('Error: {0}'.format(e))
                print('Attempting to update stack')
                try:
                  create_or_update_stack(
                      create=False, stack_name=stack_name, template_url=template_url,
                      parameters=parameters, project_id=project_id)
                except Exception as ex:
                    print('Stack may not need to be updated.')
                    print('Error: {0}'.format(ex))
                    print('Continuing as normal.')
