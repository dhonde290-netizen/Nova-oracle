import json
import boto3

# Initialize the Bedrock Runtime client
# Targeting us-east-1 as it has the widest model availability
bedrock = boto3.client(service_name='bedrock-runtime', region_name='us-east-1')

def lambda_handler(event, context):
    try:
        # Parse the input body
        body = json.loads(event.get('body', '{}'))
        user_message = body.get('prompt', '')
        
        if not user_message:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({'error': 'No prompt provided'})
            }
            
        # Use the Bedrock Converse API (standardized API for messages)
        response = bedrock.converse(
            modelId='amazon.nova-micro-v1:0',
            messages=[
                {
                    "role": "user",
                    "content": [{"text": user_message}]
                }
            ],
            inferenceConfig={
                "maxTokens": 1000,
                "temperature": 0.7
            }
        )
        
        # Extract the generated text from the response
        output_text = response['output']['message']['content'][0]['text']
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'response': output_text})
        }
        
    except Exception as e:
        print(f"Error invoking Bedrock: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json'
            },
            'body': json.dumps({'error': str(e)})
        }
