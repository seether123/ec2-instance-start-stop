import boto3

def lambda_handler(event, context):
    # Define AWS resources
    ec2_client = boto3.client('ec2')

    # Get all instances with the specified tag
    instances = ec2_client.describe_instances(Filters=[
        {'Name': 'tag:'+event['tag_key'], 'Values': [event['tag_value']]}
    ])

    # Iterate through instances and start/stop them based on the current state
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_state = instance['State']['Name']

            if instance_state == 'stopped':
                ec2_client.start_instances(InstanceIds=[instance_id])
                print(f"Instance {instance_id} started.")
            elif instance_state == 'running':
                ec2_client.stop_instances(InstanceIds=[instance_id])
                print(f"Instance {instance_id} stopped.")
            else:
                print(f"Instance {instance_id} is in an invalid state: {instance_state}")

    return {
        'statusCode': 200,
        'body': 'EC2 instances processed successfully'
    }
