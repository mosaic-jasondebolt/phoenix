"""CloudFormation macro used for additional processing of templates."""
import json
import string
import random
import os
import boto3
import botocore

__author__ = "Jason DeBolt (jasondebolt@gmail.com)"

ssm_client = boto3.client('ssm')

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

def get_macro_environment_variable_map():
    replace_map = {}
    global_ssm_path = '/microservice/{0}/global/'.format(os.environ['PHX_MACRO_PROJECT_NAME'])
    ssm_params = get_ssm_params_by_path(global_ssm_path)
    for param in ssm_params:
        param_key, param_value = param['Name'], param['Value']
        # '/microservice/{project_name}/global/some-param-key' --> 'PHX_MACRO_SOME_PARAM_KEY'
        phx_key = 'PHX_MACRO_' + param_key.split('/')[-1].replace('-', '_').upper()
        replace_map[phx_key] = param_value
    return replace_map

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
    macro_value_replace_map = get_macro_environment_variable_map()
    print('MACRO VALUES: ')
    print(json.dumps(macro_value_replace_map, indent=2, default=str))

    # Replace all values in the PHX_MACRO_* lambda map
    macro_value_replace(fragment, replace_map=macro_value_replace_map)

    # Replace API Deployment logical CloudFormation ID's with random values (or anything else with the PHX_MACRO_RANDOM constant)
    macro_key_replace(fragment, old='PHX_MACRO_RANDOM_7', new=random_uppercase_string(7))
    print('New Fragment')
    print(fragment)
    has_orphan = check_for_phx_macro_orphans(fragment)
    if has_orphan:
        return {
            "requestId": event['requestId'],
            "status": "PHX_MACRO was found in the template! See /lambda/macro/lambda_function.py for details.", # Anything but 'success' will notify cloudformation of a failure.
            "fragment": fragment
        }

    return {
        "requestId": event['requestId'],
        "status": "success",
        "fragment": fragment
    }
