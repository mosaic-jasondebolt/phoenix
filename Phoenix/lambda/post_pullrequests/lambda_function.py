import os
import json
import boto3
import botocore
import requests
from datetime import datetime
import zipfile
import tempfile
import urllib.parse
from boto3.session import Session

# Handles the final stages of the pull request pipeline, after all tests pass and the ECS container is deployed.

ssm_client = boto3.client('ssm')
code_pipeline_client = boto3.client('codepipeline')

class JSONObject:
  def __init__(self, dict):
      vars(self).update(dict)

# Assign python values to values return from github JSON reqeuest object
false = False
true = True
null = None

def put_job_success(job, message):
    """Notify CodePipeline of a successful job

    Args:
        job: The CodePipeline job ID
        message: A message to be logged relating to the job status

    Raises:
        Exception: Any exception thrown by .put_job_success_result()
    """
    print('Putting job success')
    print(message)
    code_pipeline_client.put_job_success_result(jobId=job)

def put_job_failure(job, message):
    """Notify CodePipeline of a failed job

    Args:
        job: The CodePipeline job ID
        message: A message to be logged relating to the job status

    Raises:
        Exception: Any exception thrown by .put_job_failure_result()
    """
    print('Putting job failure')
    print(message)
    code_pipeline_client.put_job_failure_result(jobId=job, failureDetails={'message': message, 'type': 'JobFailed'})

def lambda_handler(event, context):
    try:
        print(event)
        json_obj = json.dumps(event, indent=4)
        print(json_obj)
        job_id = event['CodePipeline.job']['id']
        # We must notify CodePipeline of the job status or it will block the pipeline for ages
        put_job_success(job_id, 'Function complete')
    except Exception as e:
        print('Function failed due to exception.')

        # We must notify CodePipeline of the job status or it will block the pipeline for ages
        put_job_failure(job_id, 'Function failed')
        print(e)

    print('Function complete.')
    return "Complete."
