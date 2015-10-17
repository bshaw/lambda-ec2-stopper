import boto3
import logging

#setup simple logging for INFO
logger = logging.getLogger()
logger.setLevel(logging.INFO)

#define the connection
ec2 = boto3.resource('ec2')

def lambda_handler(event, context):
    # Use the filter() method of the instances collection to retrieve
    # all running EC2 instances.
    filters1 = [{
        'Name': 'instance-state-name', 
        'Values': ['running']
    }]
    base = ec2.instances.filter(Filters=filters1)
    
    #filter again based on the AutoOff tag containing the value True
    filters2 = [{
        'Name': 'tag:AutoOff',
        'Values': ['True']
    }]
    
    instances = base.filter(Filters=filters2)
    
    #print the instances for logging purposes
    for instance in instances:
        print(instance.id)
    
    #locate all running instances
    RunningInstances = [instance.id for instance in instances]
    
    #perform the shutdown
    ec2.instances.filter(InstanceIds=RunningInstances).stop()