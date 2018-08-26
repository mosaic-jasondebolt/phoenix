import json
import logging
import uuid
import string
import random
import requests
import boto3
import copy
from requests import Request, Session

ssm_client = boto3.client('ssm')

def put_password_to_ssm(parameter_name, parameter_description, key_id, password):
    """Puts the password to SSM Parameter Store."""
    print('Putting password to parameter store')
    kwargs = {
        'Name': parameter_name,
        'Description': parameter_description,
        'Value': password,
        'Type': 'SecureString',
        'Overwrite': True
    }
    if key_id is not None:
        kwargs['KeyId'] = key_id
    response = ssm_client.put_parameter(**kwargs)
    return response

def get_password_from_ssm(parameter_name, key_id):
    """Retrieves the password from SSM Parameter Store."""
    response = ssm_client.get_parameters(
        Names=[parameter_name], WithDecryption=True)
    credentials = response['Parameters'][0]['Value']
    return credentials

def get_random_password(password_length=20):
    password = ''
    char_set = string.ascii_uppercase + string.ascii_lowercase + string.digits + '$'
    while '$' not in password:
        password = ''.join(random.sample(char_set * 6, int(password_length)))
    return password

def send_response(event, context, response_status, response_data, reason):
    """Send a Success or Failure event back to CFN stack"""

    payload = {
        'StackId': event['StackId'],
        'Status' : response_status,
        'Reason' : reason,
        'RequestId': event['RequestId'],
        'LogicalResourceId': event['LogicalResourceId'],
        'Data': response_data
    }

    payload['PhysicalResourceId'] = event.get(
        'PhysicalResourceId', str(uuid.uuid4()))

    safe_payload = copy.deepcopy(payload)
    if 'Password' in safe_payload['Data']:
        del safe_payload['Data']['Password'] # Don't display password in logs

    print("Sending %s to %s" % (json.dumps(safe_payload), event['ResponseURL']))
    requests.put(event['ResponseURL'], data=json.dumps(payload))

    print("Sent %s to %s" % (json.dumps(safe_payload), event['ResponseURL']))


def lambda_handler(event, context):
    print(json.dumps(event, indent=2))
    response_data = {}
    kms_key_id = event['ResourceProperties']['KMSKeyId']
    param_name = event['ResourceProperties']['ParameterName']
    param_description = event['ResourceProperties']['ParameterDescription']
    password_length = int(event['ResourceProperties']['PasswordLength'])
    is_new_database = bool(int(event['ResourceProperties'].get('IsNewDatabase', 0)))
    reason = 'N/A'

    if event['RequestType'] != 'Delete':
        if event['ResourceProperties']['Type'] == 'encrypt' and is_new_database:
            db_password = get_random_password(password_length)
            put_password_to_ssm(param_name, param_description, kms_key_id, db_password)
            reason = 'The value was successfully encrypted'
        else:
            response_data['Password'] = get_password_from_ssm(param_name, kms_key_id)
            reason = 'The value was successfully decrypted'

    return send_response(event, context, 'SUCCESS', response_data, reason)
