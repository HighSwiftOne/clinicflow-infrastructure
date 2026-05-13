import boto3
import json
import logging

# Set up professional logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    try:
        # Extract bucket name from the EventBridge/CloudTrail payload
        bucket_name = event['detail']['requestParameters']['bucketName']
        logger.info(f"ALARM: Public access breach detected on bucket: {bucket_name}")

        # THE REMEDIATION: Force-enable all Public Access Block settings
        s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        
        logger.info(f"SUCCESS: Vault Door Closed for {bucket_name}. HIPAA Compliance restored.")
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"Remediation successful for {bucket_name}")
        }

    except KeyError as e:
        logger.error(f"ERROR: Could not find bucket name in event payload. Event: {json.dumps(event)}")
        return {'statusCode': 400, 'body': 'Invalid event format'}
    except Exception as e:
        logger.error(f"CRITICAL FAILURE: Could not secure bucket {bucket_name}. Error: {str(e)}")
        raise e