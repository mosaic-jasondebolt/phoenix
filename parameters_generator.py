""" Converts CloudFormation parameters to the native format expected by the CLI.

Code Pipeline expects this format:
https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/continuous-delivery-codepipeline-cfn-artifacts.html#w2ab2c13c15c13

CloudFormation expects this format:
https://aws.amazon.com/blogs/devops/passing-parameters-to-cloudformation-stacks-with-the-aws-cli-and-powershell/

USAGE:
  python parameters_generator.py template.json > temp.json

  Use to the temp.json file at a parameter file in a cloudformation CLI call:
  aws cloudformation create-stack --stack-name <stack_name> --template-body file://template.json --parameters file://temp.json
"""

import sys, os, json

def convert_parameters_file(obj):
    params = obj['Parameters']
    new_obj = []

    # Add the user's username as a parameter for an optional URL prefix.
    new_obj.append(
        {'ParameterKey': 'Username', 'ParameterValue': os.environ[
            'USER'].replace('.', '-')})

    for param_key in params:
        new_obj.append(
            {'ParameterKey': param_key, 'ParameterValue': params[param_key]})
    return json.dumps(new_obj, indent=4)

def _parse_json(path):
    result = open(os.path.join(sys.path[0], path), 'rb').read()
    try:
        return json.loads(result)
    except json.decoder.JSONDecodeError as e:
        print('\nYour JSON is not valid! Did you check trailing commas??\n')
        raise(e)

def main(args):
    params_file = args[0]
    json_result = _parse_json(params_file)
    print(convert_parameters_file(json_result))

if __name__ == '__main__':
    main(sys.argv[1:])
