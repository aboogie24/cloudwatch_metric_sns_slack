from email import message
import urllib3 
import json
import os
http = urllib3.PoolManager() 

SLACK_URL = os.environ.get("SLACK_URL") 

def lambda_handler(event, context): 
    url = SLACK_URL
    msg = { 
        "channel": "lambda-slack",
        "username": "alfred.brown",
        "text": event['Records'][0]['Sns']['Message'], 
        "icon_emoji": ""
    }

    encode_msg = json.dumps(msg).encode('utf-8')
    resp = http.request('POST',url, body=encode_msg)
    print({
        "message": event['Records'][0]['Sns']['Message'],
        "status_code": resp.status, 
        "response": resp.data
    })