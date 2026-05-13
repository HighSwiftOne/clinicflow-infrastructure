import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    try:
        # Surgical extraction of the bucket name from CloudTrail/EventBridge payload
        bucket_name = event['detail']['requestParameters']['bucketName']
        
        print(f"TRIPWIRE ACTIVATED: Remediation triggered for {bucket_name}")

        # The 'Slapper': Re-applying the 4-layer Public Access Block
        s3.put_public_access_block(
            Bucket=bucket_name,
            PublicAccessBlockConfiguration={
                'BlockPublicAcls': True,
                'IgnorePublicAcls': True,
                'BlockPublicPolicy': True,
                'RestrictPublicBuckets': True
            }
        )
        
        print(f"SUCCESS: Vault Door Closed for {bucket_name}")
        return {
            'statusCode': 200,
            'body': json.dumps(f"Vault Door Closed: {bucket_name}")
        }

    except Exception as e:
        print(f"FAILED TO SLAP CLOSED: {str(e)}")
        raise e