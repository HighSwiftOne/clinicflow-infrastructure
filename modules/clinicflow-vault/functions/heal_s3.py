# DEPLOYMENT_FORCE_ID: 101_MAY13_2026
import boto3
# ... (rest of your code)
import logging
# ... (rest of the code)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    bucket_name = event['detail']['requestParameters']['bucketName']
    # Dynamic region detection
    region = event.get('awsRegion', 'us-east-1') 
    
    s3 = boto3.client('s3', region_name=region)
    try:
        s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        logger.info(f"SUCCESS: Vault Door Closed for {bucket_name}")
    except Exception as e:
        logger.error(f"FAILURE: {str(e)}")
        raise e