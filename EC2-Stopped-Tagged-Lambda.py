import boto3
import logging

#setup simple logging for INFO
logger = logging.getLogger()
logger.setLevel(logging.INFO)

#define the connection
ec2 = boto3.resource('ec2')

# get a list of all instances
all_instances = [i for i in ec2.instances.all()]

def lambda_handler(event, context):
    # # Use the filter() method of the instances collection to retrieve
    # # all running EC2 instances.
    # filters = [{
    #         'Name': 'tag:AutoOff',
    #         'Values': ['True']
    #     },
    #     {
    #         'Name': 'instance-state-name',
    #         'Values': ['running']
    #     }
    # ]
    #
    # #filter the instances
    # instances = ec2.instances.filter(Filters=filters)
    # get instances with filter of running + with tag `Name`
    instances = [i for i in ec2.instances.filter(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}, {'Name':'tag:ineedtorun', 'Values':['False']}])]

    # #locate all running instances
    # RunningInstances = [instance.id for instance in instances]
    # make a list of filtered instances IDs `[i.id for i in instances]`
    # Filter from all instances the instance that are not in the filtered list
    instances_to_delete = [to_del for to_del in all_instances if to_del.id not in [i.id for i in instances]]

    #print the instances for logging purposes
    #print RunningInstances

    # #make sure there are actually instances to shut down.
    # if len(RunningInstances) > 0:
    #     #perform the shutdown
    #     shuttingDown = ec2.instances.filter(InstanceIds=RunningInstances).stop()
    #     print shuttingDown
    # else:
    #     print "Nothing to see here"
    # run over your `instances_to_delete` list and terminate each one of them
    for instance in instances_to_delete:
        instance.stop()
