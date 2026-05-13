# Version: 1.1 - Hardened Regional Logic
import boto3
# ... rest of your code ...
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        # 1. Extract Details
        bucket_name = event['detail']['requestParameters']['bucketName']
        region = event['awsRegion'] # Get the region directly from the event
        
        logger.info(f"ALARM: Breach in {region} on bucket: {bucket_name}")

        # 2. Force Region-Specific Connection
        s3 = boto3.client('s3', region_name=region)

        # 3. The Slam Move
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
        return {'statusCode': 200, 'body': 'Fixed'}

    except Exception as e:
        logger.error(f"CRITICAL FAILURE: {str(e)}")
        raise e