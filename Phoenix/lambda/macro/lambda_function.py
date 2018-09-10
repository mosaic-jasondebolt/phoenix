"""CloudFormation macro used for additional processing of templates."""
import json
import os

__author__ = "Jason DeBolt (jasondebolt@gmail.com)"

def macro_replace(obj, old=None, new=None, replace_map=None):
    if isinstance(obj, dict):
        for key, value in obj.items():
            if isinstance(value, str):
                if old is not None and new is not None:
                    if old in value:
                        obj[key] = obj[key].replace(old, new)
                elif replace_map is not None:
                    for replace_key, replace_val in replace_map.items():
                        if replace_key in value:
                            obj[key] = obj[key].replace(replace_key, replace_val)
            else:
                macro_replace(value, old, new, replace_map)
    elif isinstance(obj, list):
        for index, item in enumerate(obj):
            if isinstance(item, str):
                if old is not None and new is not None:
                    if old in item:
                        obj[index] = obj[index].replace(old, new)
                elif replace_map is not None:
                    for replace_key, replace_val in replace_map.items():
                        if replace_key in item:
                            obj[index] = obj[index].replace(replace_key, replace_val)
            else:
                macro_replace(item, old, new, replace_map)

def get_phoenix_macro_environment_variable_map():
    replace_map = {}
    for env_variable in os.environ:
        if env_variable.startswith('PHX_MACRO_'):
            replace_map[env_variable] = os.environ[env_variable]
    return replace_map

def lambda_handler(event, context):
    print(event)
    print(os.environ)
    print(json.dumps(event, indent=2, default=str))

    fragment = event['fragment']
    phoenix_macro_replace_map = get_phoenix_macro_environment_variable_map()
    print(phoenix_macro_replace_map)
    macro_replace(fragment, replace_map=phoenix_macro_replace_map)
    print('New Fragment')
    print(fragment)

    return {
        "requestId": event['requestId'],
        "status": "success",
        "fragment": fragment
    }
