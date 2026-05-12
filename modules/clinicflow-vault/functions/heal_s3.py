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

# --- LOCAL DEBUG HARNESS ---
if __name__ == "__main__":
    import json
    import os
    
    # 1. Simulate the exact EventBridge CloudTrail Payload
    mock_event = {
        "detail": {
            "eventName": "DeleteBucketPublicAccessBlock",
            "requestParameters": {
                # UPDATE THIS to the name of your actual test bucket
                "bucketName": "clinicflow-vault-mock-target" 
            }
        }
    }

    mock_context = {}

    print("Initiating Local Lambda Execution...")
    try:
        # Trigger the function exactly as EventBridge would
        response = lambda_handler(mock_event, mock_context)
        print("\nExecution Successful. Response:")
        print(json.dumps(response, indent=2))
    except Exception as e:
        print(f"\nExecution FAILED. Exception Trapped: {e}")

        import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    try:
        # Surgical extraction of the bucket name from CloudTrail/EventBridge payload
        # SAA-C03 Tip: CloudTrail logs API calls; EventBridge routes them.
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
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"Vault Door Closed: {bucket_name}")
        }

    except Exception as e:
        print(f"FAILED TO SLAP CLOSED: {str(e)}")
        raise e