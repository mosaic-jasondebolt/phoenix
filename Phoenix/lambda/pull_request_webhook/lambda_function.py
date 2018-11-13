import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import urllib.parse
import hmac

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


# def handle_github_hook(request):
#     # Unfortunately we cannot send the request body to a Lambda custom
#     # authorizer, we we inspect here.
#     github_signature = request.META['HTTP_X_HUB_SIGNATURE']
#     signature = hmac.new('test123', request.body, hashlib.sha1)
#     expected_signature = 'sha1=' + signature.hexdigest()
#     if not hmac.compare_digest(github_signature, expected_signature):
#         return HttpResponseForbidden('Invalid signature header')


def lambda_handler(event, context):
    print(event)
    json_obj = json.dumps(event, indent=4)
    print(json_obj)
    obj = json.loads(json_obj, object_hook=JSONObject)
