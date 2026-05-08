import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    # Figure out which bucket the user just accidentally exposed
    bucket_name = event['detail']['requestParameters']['bucketName']
    print(f"BREACH ATTEMPT DETECTED: Locking down bucket {bucket_name}")
    
    # Slam the door shut and enforce HIPAA privacy
    s3.put_public_access_block(
        Bucket=bucket_name,
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': True,
            'IgnorePublicAcls': True,
            'BlockPublicPolicy': True,
            'RestrictPublicBuckets': True
        }
    )
    
    return {"status": "Bucket violently secured."}