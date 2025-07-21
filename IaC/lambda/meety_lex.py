import boto3
import uuid
from datetime import datetime

# Initialize DynamoDB resource
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

    # Helper to safely get slot values
    def get_slot_value(slot_name):
        try:
            return slots[slot_name]['value']['interpretedValue']
        except (KeyError, TypeError):
            return None

    # Extract slot values
    attendee_name = get_slot_value('FullName')
    meeting_title = get_slot_value('MeetingDuration')
    meeting_date = get_slot_value('MeetingDate')
    meeting_time = get_slot_value('MeetingTime')  # Corrected slot name
    email = get_slot_value('AttendeeEmail')
    confirm = get_slot_value('confirm')

    # Check for missing required slots before confirmation
    missing_slots = []
    if not attendee_name: missing_slots.append('FullName')
    if not meeting_title: missing_slots.append('MeetingDuration')
    if not meeting_date: missing_slots.append('MeetingDate')
    if not meeting_time: missing_slots.append('MeetingTime')
    if not email: missing_slots.append('AttendeeEmail')

    if missing_slots:
        return _response(f"Please provide the following missing information before proceeding: {', '.join(missing_slots)}.")

    # Confirm intent before proceeding
    if confirm is None:
        return _response("Do you want to proceed with the meeting? Please say 'yes' to confirm.")
    elif confirm.lower() != "yes":
        return _response("Okay, I won't schedule the meeting.")

    # All data present and confirmed
    meeting_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()

    # Prepare the DynamoDB item
    item = {
        'meetingId': meeting_id,
        'FullName': attendee_name,
        'MeetingDuration': meeting_title,
        'MeetingDate': meeting_date,
        'AttendeeEmail': email,
        'status': 'Scheduled',
        'createdAt': timestamp
    }

    # Only include MeetingTime if it exists
    if meeting_time:
        item['MeetingTime'] = meeting_time

    # Save to DynamoDB
    try:
        table.put_item(Item=item)
        print("Meeting stored in DynamoDB:", item)
        return _response(
            f"Meeting for {attendee_name} on {meeting_date} at {meeting_time} has been scheduled for {meeting_title}."
        )
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
