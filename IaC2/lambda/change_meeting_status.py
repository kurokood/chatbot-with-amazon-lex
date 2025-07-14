import boto3
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Meetings')


def lambda_handler(event, context):

    request_body = json.loads(event['body'])
    meeting_id = request_body['meetingId']
    new_status = request_body['newStatus']

    try:
        table.update_item(
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

        return {
                'statusCode': 200,
                'body': 'status successfully changed'
            }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': 'Failed to update meeting status'
        }
