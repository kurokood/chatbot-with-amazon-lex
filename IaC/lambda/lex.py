import boto3
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key, Attr
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Meetings')


def get_session_attributes(intent_request):
    sessionState = intent_request['sessionState']
    if 'sessionAttributes' in sessionState:
        return sessionState['sessionAttributes']

    return {}


def get_slots(intent_request):
    return intent_request['sessionState']['intent']['slots']


def get_slot(intent_request, slotName):
    slots = get_slots(intent_request)
    if slots is not None and slotName in slots and slots[slotName] is not None:
        return slots[slotName]['value']['interpretedValue']
    else:
        return None


def close(intent_request, session_attributes, fulfillment_state, message):
    intent_request['sessionState']['intent']['state'] = fulfillment_state
    return {
        'sessionState': {
        'sessionAttributes': session_attributes,
        'dialogAction': {
            'type': 'Close'
            },
            'intent': intent_request['sessionState']['intent']
            },
        'messages': [message],
        'sessionId': intent_request['sessionId'],
        'requestAttributes': intent_request['requestAttributes'] if 'requestAttributes' in intent_request else None,

    }


def calculate_end_time(start_time_str, duration_minutes):

    start_time = datetime.strptime(start_time_str, '%H:%M').time()
    end_time = (datetime.combine(datetime.min, start_time) + timedelta(minutes=duration_minutes)).time()
    end_time_str = end_time.strftime('%H:%M')

    return end_time_str


def check_meeting_slot(prop_date, prop_start, prop_dur):

    proposed_date = datetime.strptime(prop_date, '%Y-%m-%d').date()
    proposed_start_time = datetime.strptime(prop_start, '%H:%M').time()
    proposed_end_time = (datetime.combine(proposed_date, proposed_start_time) + timedelta(minutes=prop_dur)).time()
    start_time_str = proposed_start_time.strftime('%H:%M')
    end_time_str = proposed_end_time.strftime('%H:%M')
    query_response = table.query(
        IndexName='StatusIndex',
        KeyConditionExpression=Key('status').eq('approved') & Key('date').eq(proposed_date.isoformat()),
        FilterExpression=(Attr('startTime').gt(start_time_str) & Attr('startTime').lt(end_time_str)) | Attr('startTime').eq(start_time_str) | (Attr('endTime').gt(start_time_str) & Attr('endTime').lt(end_time_str))
        )

    if query_response['Items']:
        return False
    else:
        return True


def create_meeting(intent_request):

    session_attributes = get_session_attributes(intent_request)
    proposed_date = get_slot(intent_request, 'MeetingDate')
    proposed_start_time = get_slot(intent_request, 'MeetingTime')
    proposed_duration = get_slot(intent_request, 'MeetingDuration')
    email = get_slot(intent_request, 'AttendeeEmail')
    name = get_slot(intent_request, 'FullName')
    meeting_id = str(uuid.uuid4())
    proposed_end_time = calculate_end_time(proposed_start_time, int(proposed_duration))
    is_conflict = not check_meeting_slot(proposed_date, proposed_start_time, int(proposed_duration))

    item = {
                'meetingId': meeting_id,
                'attendeeName': name,
                'email': email,
                'date': proposed_date,
                'duration': proposed_duration,
                'startTime': proposed_start_time,
                'endTime': proposed_end_time,
                'status': 'pending',
                'isConflict': is_conflict
            }

    table.put_item(Item=item)

    text = f"Thank you {name}. Your meeting request for {proposed_date} from {proposed_start_time} to {proposed_end_time} has been created. Have a nice day!"
    message = {
                'contentType': 'PlainText',
                'content': text
            }

    return close(intent_request, session_attributes, "Fulfilled", message)


def handle_req(intent_request):
    intent_name = intent_request['sessionState']['intent']['name']
    response = None
    if intent_name == 'BookMeeting':
        return create_meeting(intent_request)
    else:
        return response


def lambda_handler(event, context):
    response = handle_req(event)
    return response
