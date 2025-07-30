import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    # CORS headers
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
        'Content-Type': 'application/json'
    }
    
    try:
        # Debug: Print the event structure
        print(f"Event received: {json.dumps(event, indent=2)}")
        
        # Handle OPTIONS request for CORS preflight
        # API Gateway v2 uses 'requestContext.http.method' instead of 'httpMethod'
        http_method = event.get('requestContext', {}).get('http', {}).get('method', 'GET')
        
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': ''
            }
        
        response = table.query(
            IndexName='StatusIndex',
            KeyConditionExpression=boto3.dynamodb.conditions.Key('status').eq('pending')
        )

        pending_meetings = response['Items']

        while 'LastEvaluatedKey' in response:
            response = table.query(
                IndexName='StatusIndex',
                KeyConditionExpression=boto3.dynamodb.conditions.Key('status').eq('pending'),
                ExclusiveStartKey=response['LastEvaluatedKey']
            )
            pending_meetings.extend(response['Items'])

        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps(pending_meetings)
        }
        
    except Exception as e:
        print(f"Error in get_pending_meetings: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
