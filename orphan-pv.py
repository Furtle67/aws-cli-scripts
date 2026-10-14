import boto3
import subprocess
import json


session=boto3.Session(profile_name='nphase', region_name='us-east-1')
ec2 = session.client('ec2')

# Get all pvc EBS volumes
volumes = ec2.describe_volumes(
    Filters=[
        {'Name': 'tag:Name', 'Values': ['*pvc*']},
        {'Name': 'status', 'Values': ['available']}  # detached only
    ]
)['Volumes']

# Get all PV volume handles from kubectl
result = subprocess.run(
    ['kubectl', 'get', 'pv', '-o', 'json'],
    capture_output=True, text=True
)
pvs = json.loads(result.stdout)
k8s_volume_ids = set()
for pv in pvs['items']:
    vid = (pv.get('spec', {}).get('csi', {}).get('volumeHandle') or
           pv.get('spec', {}).get('awsElasticBlockStore', {}).get('volumeID', ''))
    if vid:
        k8s_volume_ids.add(vid.split('/')[-1])  # strip az prefix if present

print(f"{'Volume ID':<25} {'Name':<50} {'Size':>6} {'Created'}")
print("-" * 100)
orphaned = []
for v in volumes:
    vid = v['VolumeId']
    name = next((t['Value'] for t in v.get('Tags', []) if t['Key'] == 'Name'), 'unnamed')
    if vid not in k8s_volume_ids:
        print(f"{vid:<25} {name:<50} {v['Size']:>5}Gi  {v['CreateTime'].strftime('%Y-%m-%d')}")
        orphaned.append(vid)

print(f"\nOrphaned volumes: {len(orphaned)} ({sum(v['Size'] for v in volumes if v['VolumeId'] in orphaned)}Gi total)")
