import os
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

def lambda_handler(event, context):
    print(event)
    json_obj = json.dumps(event, indent=4)
    print(json_obj)
    obj = json.loads(json_obj, object_hook=JSONObject)
    if obj.object_kind != 'push':
      raise Exception('Object is not a push! object is of type' + obj.object_kind)
