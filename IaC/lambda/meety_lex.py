import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Meetings')


def lambda_handler(event, context):
    print("Received event:", event)

    # Extract intent and slots
    try:
        intent = event['sessionState']['intent']
        slots = intent.get('slots', {})
    except KeyError:
        return _response("Sorry, I couldn't process your request.")

    # Extract slot values safely
    def get_slot_value(slot_name):
        try:
            return slots[slot_name]['value']['interpretedValue']
        except (KeyError, TypeError):
            return None

    attendee_name = get_slot_value('attendeeName')
    meeting_title = get_slot_value('meetingTitle')
    meeting_date = get_slot_value('date')
    meeting_time = get_slot_value('time')
    email = get_slot_value('email')
    confirm = get_slot_value('confirm')

    if confirm is None or confirm.lower() != "yes":
        return _response("Okay, I won't schedule the meeting.")

    # Create a new meeting item
    meeting_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()

    item = {
        'meetingId': meeting_id,
        'attendeeName': attendee_name,
        'meetingTitle': meeting_title,
        'date': meeting_date,
        'time': meeting_time,
        'email': email,
        'status': 'Scheduled',
        'createdAt': timestamp
    }

    try:
        table.put_item(Item=item)
        print("Meeting stored in DynamoDB:", item)
        return _response(f"Meeting '{meeting_title}' with {attendee_name} on {meeting_date} at {meeting_time} has been scheduled.")
    except Exception as e:
        print("Error storing in DynamoDB:", str(e))
        return _response("There was an error scheduling the meeting. Please try again later.")


def _response(message):
    return {
        "sessionState": {
            "dialogAction": {
                "type": "Close"
            },
            "intent": {
                "name": "MeetingAssistant",
                "state": "Fulfilled"
            }
        },
        "messages": [
            {
                "contentType": "PlainText",
                "content": message
            }
        ]
    }
