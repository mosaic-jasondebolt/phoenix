import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse

# Handles GitHub merge request events

# For the full GitHub Pull Request REST API:
# https://developer.github.com/v3/activity/events/types/#pullrequestevent

cloudformation_client = boto3.client('cloudformation')
ssm_client = boto3.client('ssm')

class JSONObject:
  def __init__(self, dict):
      vars(self).update(dict)

# Assign python values to values return from github JSON reqeuest object
false = False
true = True
null = None

def lambda_handler(event, context):
    print(event)
    json_obj = json.dumps(event, indent=4)
    print(json_obj)
    obj = json.loads(json_obj, object_hook=JSONObject)
