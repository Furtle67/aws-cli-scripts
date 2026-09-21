#!/bin/bash
##############################
##
##  Check an iamge is safe to delete
#
#  How to read the results
#  Section 1 — any instance listed means the AMI produced live instances.
#   Deregistering won't kill those instances (they keep running),
#   but it tells you the image was actually used, so investigate before removing.
#  
#  Sections 2–4 — this is the real risk. If a launch template, launch configuration, or ASG points 
#  at image, deregistering it will break future launches/scale-outs from that automation.
#   Section 4 shows each ASG's LT/LC — cross-reference any IDs that showed hits in 2 or 3.
# 
# Section 5 — active fleets referencing the AMI would also break.
# Section 6 — if this returns enabled, you'll have to disable deregistration protection first
#  (and wait out any cooldown) before you can deregister.
#
# Section 7 — the snapshot(s) you'll be able to delete once the AMI is gone:
# your cost saving.How to read the results
#
#
#
# Usage: ./ami-check.sh <ami-id> [profile] [region]
# Example: ./ami-check.sh ami-8973cded nphase us-east-1
#
##
#################################


AMI="$1"
PROFILE="${2:-nphase}"          # defaults to nphase if not passed
REGION_ARG=""
[ -n "$3" ] && REGION_ARG="--region $3"

# --- validate input ---
if [ -z "$AMI" ]; then
  echo "Usage: $0 <ami-id> [profile] [region]"
  echo "Example: $0 ami-8973cded nphase us-east-1"
  exit 1
fi

echo "==================================================="
echo " Cross-reference check for $AMI"
echo " Profile: $PROFILE   Region: ${3:-<default>}"
echo "==================================================="

echo -e "\n--- 0. Does the AMI exist / is it yours? ---"
aws ec2 describe-images --profile "$PROFILE" $REGION_ARG --image-ids "$AMI" \
  --query 'Images[].[ImageId,Name,State,CreationDate,Description]' \
  --output table 2>/dev/null || echo "  AMI not found (wrong region/profile, or already deregistered)"

echo -e "\n--- 1. Instances launched from this AMI (running or stopped) ---"
aws ec2 describe-instances --profile "$PROFILE" $REGION_ARG \
  --filters "Name=image-id,Values=$AMI" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`]|[0].Value]' \
  --output table

echo -e "\n--- 2. Launch Templates referencing this AMI (all versions) ---"
for lt in $(aws ec2 describe-launch-templates --profile "$PROFILE" $REGION_ARG \
              --query 'LaunchTemplates[].LaunchTemplateId' --output text); do
  hits=$(aws ec2 describe-launch-template-versions --profile "$PROFILE" $REGION_ARG \
           --launch-template-id "$lt" \
           --query "LaunchTemplateVersions[?LaunchTemplateData.ImageId=='$AMI'].[VersionNumber]" \
           --output text)
  [ -n "$hits" ] && echo "  Launch template $lt -> version(s): $hits"
done

echo -e "\n--- 3. Launch Configurations referencing this AMI (legacy ASG) ---"
aws autoscaling describe-launch-configurations --profile "$PROFILE" $REGION_ARG \
  --query "LaunchConfigurations[?ImageId=='$AMI'].[LaunchConfigurationName]" \
  --output table

echo -e "\n--- 4. Auto Scaling Groups (check their LT/LC references) ---"
aws autoscaling describe-auto-scaling-groups --profile "$PROFILE" $REGION_ARG \
  --query 'AutoScalingGroups[].[AutoScalingGroupName,LaunchConfigurationName,LaunchTemplate.LaunchTemplateId,MixedInstancesPolicy.LaunchTemplate.LaunchTemplateSpecification.LaunchTemplateId]' \
  --output table

echo -e "\n--- 5. EC2 Spot Fleet requests (active) ---"
aws ec2 describe-spot-fleet-requests --profile "$PROFILE" $REGION_ARG \
  --query "SpotFleetRequestConfigs[?SpotFleetRequestState=='active'].[SpotFleetRequestId]" \
  --output text 2>/dev/null

echo -e "\n--- 6. Is the AMI protected from deregistration? ---"
aws ec2 describe-image-attribute --profile "$PROFILE" $REGION_ARG \
  --image-id "$AMI" --attribute deregistrationProtection \
  --query 'DeregistrationProtection' --output text 2>/dev/null

echo -e "\n--- 7. SSM Parameters holding this AMI ID ---"
aws ssm get-parameters-by-path --profile "$PROFILE" $REGION_ARG --path "/" --recursive \
  --query "Parameters[?Value=='$AMI'].[Name,Value]" --output table 2>/dev/null \
  || echo "  (none, or no SSM access)"

echo -e "\n--- 8. Snapshots backing this AMI (what you'd reclaim) ---"
aws ec2 describe-images --profile "$PROFILE" $REGION_ARG --image-ids "$AMI" \
  --query 'Images[].BlockDeviceMappings[].[DeviceName,Ebs.SnapshotId,Ebs.VolumeSize]' \
  --output table


echo "If its safe you can delete them:"
echo "          aws ec2 deregister-image --profile nphase --delete-associated-snapshots  --image-id $AMI"



