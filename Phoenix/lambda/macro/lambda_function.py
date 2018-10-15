"""CloudFormation macro used for additional processing of templates."""
import json
import string
import random
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

def random_uppercase_string(str_len):
    return ''.join([random.choice(string.ascii_uppercase) for _ in range(str_len)])

def macro_value_replace(obj, old=None, new=None, replace_map=None):
    # This function only replaces values in a JSON CloudFormation template, not keys.
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(value, str):
                if old is not None and new is not None:
                    if old in value:
                        obj[key] = obj[key].replace(old, new)
                elif replace_map is not None:
                    # Reverse sorting by dict key length forces matches on the larger string before any overlapping smaller strings.
                    for replace_key in sorted(replace_map, key=len, reverse=True):
                        replace_val = replace_map[replace_key]
                        if replace_key in value:
                            obj[key] = obj[key].replace(replace_key, replace_val)
            else:
                macro_value_replace(value, old, new, replace_map)
    elif isinstance(obj, list):
        for index, item in enumerate(obj):
            if isinstance(item, str):
                if old is not None and new is not None:
                    if old in item:
                        obj[index] = obj[index].replace(old, new)
                elif replace_map is not None:
                    # Reverse sorting by dict key length forces matches on the larger string before any overlapping smaller strings.
                    for replace_key in sorted(replace_map, key=len, reverse=True):
                        replace_val = replace_map[replace_key]
                        if replace_key in item:
                            obj[index] = obj[index].replace(replace_key, replace_val)
            else:
                macro_value_replace(item, old, new, replace_map)

def macro_key_replace(obj, old=None, new=None):
    # This function only replaces keys in a JSON CloudFormation template, not values.
    # Updates only the part of they key that matches.
    # {"old123": ...} --> {"new123": ...}
    # TODO (jasondebolt): Sort dict by reverse key length like above to avoid matching on overlapping substrings.
    if isinstance(obj, dict):
        for key, value in obj.items():
            if old is not None and new is not None:
                if old in key:
                    new_key = key.replace(old, new)
                    obj[new_key] = obj[key]
                    del obj[key]
            macro_key_replace(value, old, new)
    elif isinstance(obj, list):
        for index, item in enumerate(obj):
            macro_key_replace(item, old, new)

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

def check_for_phx_macro_orphans(fragment):
    # Checks if there are any remaining PHX_MACRO strings in the tempalte that may not have been replaced due to typos.
    print('Checking for orphaned PHX_MACRO references.')
    str_fragment = str(fragment)
    if 'PHX_MACRO' in str_fragment:
        print('PHX_MACRO was found in the template! There should be no PHX_MACRO')
        return True
    return False

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

    # Replace API Deployment logical CloudFormation ID's with random values (or anything else with the PHX_MACRO_RANDOM constant)
    macro_key_replace(fragment, old='PHX_MACRO_RANDOM_7', new=random_uppercase_string(7))
    print('New Fragment')
    print(fragment)
    has_orphan = check_for_phx_macro_orphans(fragment)
    if has_orphan:
        # TODO (jasondebolt): Follow up with AWS support to see if there's a way to send this error message back to CloudFormation so our developers don't have to dig into the Lambda logs.
        print("The string 'PHX_MACRO' was found somewhere in your template after the template was processed! Please check your template for 'PHX_MACRO' references that were possibly mistyped as a typos.")
        return # Anything but 'success' will notify cloudformation of a failure.

    return {
        "requestId": event['requestId'],
        "status": "success",
        "fragment": fragment
    }
