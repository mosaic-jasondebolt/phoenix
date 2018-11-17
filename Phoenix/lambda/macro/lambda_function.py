"""CloudFormation macro used for additional processing of templates."""
import json
import string
import os
import boto3
import botocore

__author__ = "Jason DeBolt (jasondebolt@gmail.com)"

ssm_client = boto3.client('ssm')

PROJECT_NAME = os.environ['PHX_MACRO_PROJECT_NAME']

def get_ssm_params_by_path(path):
    """ Returns a list of SSM parameter object.
    [
        {
          "Name": "...",
          "Type": "String",
          "Value": "...",
          "Version": 1,
          "LastModifiedDate": "2018-09-13 14:11:39.928000-07:00",
          "ARN": "..."
        },
        ...
    ]
    """
    result = []
    next_token = ''
    while True:
        args = {
            'Path': path,
            'Recursive': True,
            'WithDecryption': False,
            'MaxResults': 10,
        }
        if next_token:
            args['NextToken'] = next_token
        response = ssm_client.get_parameters_by_path(**args)
        result.extend(response['Parameters'])
        if not response.get('NextToken'):
            break
        next_token = response['NextToken']
    print(json.dumps(result, indent=2, default=str))
    return result

def get_ssm_map():
    replace_map = {}
    ssm_path = '/microservice/{0}/'.format(PROJECT_NAME)
    ssm_params = get_ssm_params_by_path(ssm_path)
    for param in ssm_params:
        param_key, param_value = param['Name'], param['Value']
        # '/microservice/{project_name}/global/some-param-key' --> 'PHX_MACRO_SOME_PARAM_KEY'
        replace_map[param_key] = param_value
    return replace_map

def macro_phoenix_ssm_replace(obj, replace_map, params_map):
    # Replaces dicts of {"PhoenixSSM": /microservice/{ProjectName}/../{Environment}/...}  with SSM values.
    if isinstance(obj, dict):
        for key in obj:
            if isinstance(obj[key], dict):
              if "PhoenixSSM" in obj[key]:
                  PhoenixVal = obj[key]["PhoenixSSM"].format(**params_map)
                  replace_val = replace_map.get(PhoenixVal)
                  if replace_val is not None:
                      obj[key] = replace_val
        for key, value in obj.items():
            macro_phoenix_ssm_replace(value, replace_map, params_map)
    elif isinstance(obj, list):
        for index, item in enumerate(obj):
            if isinstance(item, dict):
                if "PhoenixSSM" in item:
                    PhoenixVal = item["PhoenixSSM"].format(**params_map)
                    replace_val = replace_map.get(PhoenixVal)
                    if replace_val is not None:
                        obj[index] = replace_val
            macro_phoenix_ssm_replace(item, replace_map, params_map)

def lambda_handler(event, context):
    print(event)
    print(os.environ)
    print(json.dumps(event, indent=2, default=str))

    fragment = event['fragment']
    replace_map = get_ssm_map()
    params_map = event['templateParameterValues']
    params_map.update({'ProjectName': PROJECT_NAME}) # Add the ProjectName to the params map
    print('REPLACE_MAP:', json.dumps(replace_map, indent=2, default=str))

    macro_phoenix_ssm_replace(fragment, replace_map, params_map)
    print(json.dumps(fragment, indent=2, default=str))

    return {
        "requestId": event['requestId'],
        "status": "success",
        "fragment": fragment
    }
