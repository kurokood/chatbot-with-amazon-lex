import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])

def lambda_handler(event, context):
    print(f"Event received: {event}")
    print(f"Context: {context}")
    
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
        
        # Parse request body
        try:
            request_body = json.loads(event['body'])
        except json.JSONDecodeError:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Invalid JSON in request body'
                })
            }
        
        meeting_id = request_body.get('meetingId')
        new_status = request_body.get('newStatus')

        if not meeting_id or not new_status:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Missing required fields: meetingId or newStatus'
                })
            }

        # Validate status values
        valid_statuses = ['pending', 'confirmed', 'cancelled', 'approved']
        if new_status not in valid_statuses:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': f'Invalid status. Must be one of: {", ".join(valid_statuses)}'
                })
            }

        try:
            response = table.update_item(
                Key={
                    'meetingId': meeting_id
                },
                UpdateExpression='SET #status = :new_status',
                ExpressionAttributeNames={
                    '#status': 'status'
                },
                ExpressionAttributeValues={
                    ':new_status': new_status
                },
                ReturnValues='ALL_NEW'
            )

            response_body = {
                'message': 'Status successfully changed',
                'meeting': response.get('Attributes', {})
            }
            print(f"Returning response: {response_body}")
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps(response_body)
            }
        except dynamodb.meta.client.exceptions.ResourceNotFoundException:
            return {
                'statusCode': 404,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Meeting not found'
                })
            }
        except Exception as e:
            print(f"DynamoDB error: {str(e)}")
            return {
                'statusCode': 500,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Failed to update meeting status'
                })
            }
            
    except Exception as e:
        print(f"Error in change_meeting_status: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'error': 'Internal server error'
            })
        }
