import json

def lambda_handler(event, context):
    """
    Lambda function to handle OPTIONS requests for CORS preflight
    """
    print(f"Event received: {json.dumps(event)}")
    
    # Use wildcard origin for testing
    
    # CORS headers
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token,Accept,Origin',
        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
        # No credentials with wildcard origin
        'Access-Control-Max-Age': '300'
    }
    
    # Return a simple 200 OK with CORS headers for preflight requests
    return {
        'statusCode': 200,
        'headers': headers,
        'body': json.dumps({
            'status': 'success',
            'message': 'CORS preflight successful'
        })
    }