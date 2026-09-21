#!/bin/dash
#

#nphase
for region in $(aws  --profile nphase ec2 describe-regions --query 'Regions[*].RegionName' --output text); do
  echo "=== $region ==="
  aws --profile nphase ec2 describe-addresses  --region us-east-1     --query 'Addresses[*].[PublicIp,PrivateIpAddress,ServiceManaged,NetworkBorderGroup,NetworkInterfaceOwnerId,InstanceId,AllocationId,AssociationId, (Tags[?Key==`Name`].Value)[0]]'  | jq -r '.[]|@csv'  >>ip_list.tsv
  
done

#pfizer
#for region in $(aws  --profile pfizer ec2 describe-regions --query 'Regions[*].RegionName' --output text); do
#  echo "=== $region ==="
#  aws --profile pfizer ec2 describe-addresses  --region us-east-1     --query 'Addresses[*].[PublicIp,PrivateIpAddress,ServiceManaged,NetworkBorderGroup,NetworkInterfaceOwnerId,InstanceId,AllocationId,AssociationId, (Tags[?Key==`Name`].Value)[0]]'  | jq -r '.[]|@csv'  >>ip_list.tsv
#done
#
#
#
# all lbass
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?Scheme==`internet-facing`].LoadBalancerArn' \
  --output text | tr '\t' '\n' | while read arn; do
    aws elbv2 describe-listeners --load-balancer-arn "$arn" \
      --query "Listeners[?Protocol=='HTTPS'].[LoadBalancerArn,Port,SslPolicy]" \
      --output table

  # Show net balancers
    aws ec2 describe-network-interfaces \
  --filters Name=association.public-ip,Values="*" \
  --query 'NetworkInterfaces[*].[
    Association.PublicIp,
    (TagSet[?Key==`Name`].Value)[0],
    NetworkInterfaceId,
    Description
  ]'


