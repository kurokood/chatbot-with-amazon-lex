import json
import boto3
import os
from datetime import datetime, timedelta
import uuid
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
TABLE_NAME = os.environ.get('DYNAMODB_TABLE', 'Meetings')
table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        intent_name = event['sessionState']['intent']['name']
        intent_state = event['sessionState']['intent'].get('state', '')
        confirmation_state = event['sessionState']['intent'].get('confirmationState', '')
        slots = event['sessionState']['intent'].get('slots', {})

        logger.info(f"Intent name: {intent_name}")
        logger.info(f"Intent state: {intent_state}")
        logger.info(f"Confirmation state: {confirmation_state}")
        logger.info(f"Slots: {json.dumps(slots)}")

        if intent_name == 'StartMeety':
            return close_intent(intent_name, "Fulfilled")

        if intent_name == 'CustomFallbackIntent' or intent_name == 'AMAZON.FallbackIntent':
            return fallback_response(intent_name)

        if intent_name == 'MeetingAssistant':
            required_slots = ['b_MeetingDate', 'c_MeetingTime', 'a_FullName', 'd_MeetingDuration', 'e_AttendeeEmail']
            all_slots_filled = all(
                slots.get(s) and slots[s].get('value') and slots[s]['value'].get('interpretedValue')
                for s in required_slots
            )

            if all_slots_filled:
                # Handle confirmation manually via the 'f_Confirm' slot
                user_confirm = slots.get('f_Confirm', {}).get('value', {}).get('interpretedValue', '').lower()

                if user_confirm in ['yes', 'y']:
                    confirmation_state = 'Confirmed'
                elif user_confirm in ['no', 'n']:
                    confirmation_state = 'Denied'

            # If confirmed, save meeting
            if confirmation_state == 'Confirmed':
                meeting_info = {
                    'date': slots['b_MeetingDate']['value']['interpretedValue'],
                    'time': slots['c_MeetingTime']['value']['interpretedValue'],
                    'attendee_name': slots['a_FullName']['value']['interpretedValue'],
                    'duration': parse_duration(slots['d_MeetingDuration']['value']['interpretedValue']),
                    'email': slots['e_AttendeeEmail']['value']['interpretedValue']
                }

                meeting_id = str(uuid.uuid4())
                end_time = calculate_end_time(meeting_info['time'], meeting_info['duration'])

                item = {
                    'meetingId': meeting_id,
                    'attendeeName': meeting_info['attendee_name'],
                    'date': meeting_info['date'],
                    'startTime': meeting_info['time'],
                    'endTime': end_time,
                    'email': meeting_info['email'],
                    'status': 'pending',
                    'createdAt': datetime.now().isoformat()
                }

                logger.info(f"Saving meeting to DynamoDB: {json.dumps(item)}")
                table.put_item(Item=item)

                formatted_date = format_date(meeting_info['date'])
                return close_intent(intent_name, "Fulfilled", f"""Perfect! I've scheduled your meeting:

📅 Date: {formatted_date}
🕐 Time: {meeting_info['time']}
👤 Attendee: {meeting_info['attendee_name']}
📧 Email: {meeting_info['email']}

Your meeting has been scheduled successfully!""")

            elif confirmation_state == 'Denied':
                return close_intent(intent_name, "Failed", "I've cancelled the meeting request. Is there anything else I can help you with?")

            else:
                return delegate()

        return delegate()

    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return close_intent(intent_name, "Failed", f"I'm sorry, I encountered an error: {str(e)}")


def parse_duration(iso_duration):
    """Parses ISO 8601 duration like PT30M into minutes"""
    try:
        if iso_duration.startswith("PT") and iso_duration.endswith("M"):
            return int(iso_duration[2:-1])
    except Exception as e:
        logger.error(f"Error parsing duration: {str(e)}")
    return 60  # default

def calculate_end_time(start_time, duration_minutes):
    try:
        if 'am' in start_time.lower() or 'pm' in start_time.lower():
            hour = int(start_time.lower().replace('am', '').replace('pm', '').strip())
            if 'pm' in start_time.lower() and hour < 12:
                hour += 12
            if 'am' in start_time.lower() and hour == 12:
                hour = 0
            start_time = f"{hour:02d}:00"

        if ':' not in start_time:
            start_time += ":00"

        hour, minute = map(int, start_time.split(":"))
        start_dt = datetime.now().replace(hour=hour, minute=minute, second=0, microsecond=0)
        end_dt = start_dt + timedelta(minutes=duration_minutes)
        return end_dt.strftime('%H:%M')
    except Exception as e:
        logger.error(f"Error calculating end time: {str(e)}")
        return "Unknown"

def format_date(date_str):
    try:
        parsed_date = datetime.strptime(date_str, '%Y-%m-%d')
        return parsed_date.strftime('%A, %B %d, %Y')
    except Exception:
        return date_str

def close_intent(intent_name, state, message=None):
    response = {
        'sessionState': {
            'dialogAction': {
                'type': 'Close'
            },
            'intent': {
                'name': intent_name,
                'state': state
            }
        }
    }
    if message:
        response['messages'] = [{
            'contentType': 'PlainText',
            'content': message
        }]
    return response

def fallback_response(intent_name):
    return {
        'sessionState': {
            'dialogAction': {
                'type': 'Close'
            },
            'intent': {
                'name': intent_name,
                'state': 'Fulfilled'
            }
        },
        'messages': [
            {
                'contentType': 'PlainText',
                'content': "Sorry, I didn't understand that. I'm here to help you schedule meetings. Would you like to do that?"
            }
        ]
    }

def delegate():
    return {
        'sessionState': {
            'dialogAction': {
                'type': 'Delegate'
            }
        }
    }
