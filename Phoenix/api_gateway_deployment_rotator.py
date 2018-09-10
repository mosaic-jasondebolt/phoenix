"""
Generates a CloudFormation template for managing multiple API Gateway deployments.

Details:
https://forums.aws.amazon.com/thread.jspa?messageID=734405

API Gateway deployments require a new CloudFormation "AWS::ApiGateway::Deployment"
resource for each API deployment. An API deployment is like a snapshot of an API,
and it cannot be updated. Each time you change an API, you must create a new
deployment resource for the API to be available behind the URL Endpoint for the
API.

I did not feel it should be a requirement for a developer to understand how
to add a CloudFormation API Gateway deployment resource to a template, so
I created this script to automate the deployment of APIs.

AWS limits specificy that there can only be 10 API stages deployed for a given API.
This script takes care of rotating the last 10 API deployments.

While we could have used multiple deployments per stage, I found that it's simpler
to just have a single deployment per stage, with up to 10 stages of the API.

This script will generate a CloudFormation template with a new
AWS::ApiGateway::Deployment resource that points to the current API
configuration for the REST API. If there are already 10 stages associated
with the REST API, the earliest stage will be deleted.

USAGE:
  python api-gateway-deployment-generator.py {params_file} > {output template}
"""

__author__ = "Jason DeBolt (jasondebolt@gmail.com)"

import boto3
import botocore
import sys
import os
import json
import copy

client = boto3.client('cloudformation')

class APIGatewayDeployment(object):
    def __init__(self, deployment_id, stage_variables):
        self.deployment_id = deployment_id
        self.stage_variables = stage_variables


def get_deployment_resource(api_gateway_deployment_obj):
    """Returns an API Gateway Deployment CloudFormation resource."""
    return {
        "Type": "AWS::ApiGateway::Deployment",
        "Properties": {
            "RestApiId": {
                "Fn::ImportValue": {
                    "Fn::Join": ["-", [
                        "PHX_MACRO_PROJECT_NAME",
                        "api",
                        {"Ref": "Environment"},
                        "RestApiId"
                    ]]
                }
            },
            "Description": "Description here",
            "StageDescription": {
              "Description": "Stage Description",
              "LoggingLevel": "INFO",
              "MetricsEnabled": "true",
              "Variables": api_gateway_deployment_obj.stage_variables
            },
            "StageName": {
              "Fn::Join": ["_", [
                  {"Ref": "Environment"},
                  str(api_gateway_deployment_obj.deployment_id)
              ]]
            }
        }
    }

def get_blank_template():
    return {
        "AWSTemplateFormatVersion": "2010-09-09",
        "Description": "Deploys an API (RESTful or not)",
        "Parameters": {
          "ProjectName": {
            "Description": "The name of the project.",
            "Type": "String"
          },
          "Environment": {
            "Description": "The environment (dev, testing, prod, etc.) to deploy to.",
            "Type": "String"
          },
          "Version": {
            "Description": "The identifier/version associated with this API Deployment.",
            "Type": "String"
          }
        },
        "Resources": {
        }
    }


def get_template_stats(template_body):
    """Returns API Deployment information for a given template."""
    resources = template_body['Resources']
    api_gateway_deployment_count = 0
    min_deployment_id = 99999999999
    max_deployment_id = 0
    for resource_name, resource in resources.items():
        if resource['Type'] == 'AWS::ApiGateway::Deployment':
            api_gateway_deployment_count += 1
            min_deployment_id = min(min_deployment_id, int(resource_name))
            max_deployment_id = max(max_deployment_id, int(resource_name))
    return {
        'api_gateway_deployment_count': api_gateway_deployment_count,
        'min_deployment_id': min_deployment_id,
        'max_deployment_id': max_deployment_id}

def delete_oldest_api_deployment(template_body, min_deployment_id):
    """Drops the oldest stage in the deployment to make space for a new stage."""
    resources_dict = template_body['Resources']
    del resources_dict[str(min_deployment_id)]

def add_new_stage_to_template(template_body, max_deployment_id):
    deployment_id = int(max_deployment_id) + 1
    api_gateway_deployment_obj = APIGatewayDeployment(
        deployment_id, {"TestKey": "hello"})
    new_deployment = get_deployment_resource(api_gateway_deployment_obj)
    template_body['Resources'][deployment_id] = new_deployment

def parse_json(path):
    result = open(os.path.join(sys.path[0], path), 'rb').read()
    try:
        return json.loads(result)
    except json.decoder.JSONDecodeError as e:
        print('\nYour JSON is not valid! Did you check trailing commas??\n')
        raise(e)

def get_params(params_file):
    return parse_json(params_file)

def main(args):
    params = get_params(args[0])
    project_name = params['Parameters']['ProjectName']
    environment = params['Parameters']['Environment']
    stack_name = '{0}-api-deployment-{1}'.format(project_name, environment)

    try:
        existing_template = client.get_template(StackName=stack_name)
        existing_template_body = existing_template['TemplateBody']
    except botocore.exceptions.ClientError:
        existing_template_body = get_blank_template()

    # Use a deep copy just to be safe.
    new_template_body = copy.deepcopy(existing_template_body)

    template_stats = get_template_stats(new_template_body)
    #print(template_stats)

    # API Gateway only allows us to have up to 10 Stages.
    # We only want one deployment per stage, so one of the stages must be dropped.
    # I've set this to 8 to leave a buffer just in case a stack gets updated too quickly.
    while template_stats['api_gateway_deployment_count'] >= 8:
        delete_oldest_api_deployment(
            new_template_body, template_stats['min_deployment_id'])
        template_stats = get_template_stats(new_template_body)

    add_new_stage_to_template(new_template_body, template_stats['max_deployment_id'])

    print(json.dumps(new_template_body, indent=2))
    template_stats = get_template_stats(new_template_body)
    #print(template_stats)


if __name__ == '__main__':
    main(sys.argv[1:])
