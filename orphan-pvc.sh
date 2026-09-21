# List all EBS volumes with pvc in the name/tag
aws --profile pfizer  ec2 describe-volumes --region us-east-1 \
  --filters \
    "Name=tag:Name,Values=*pvc*" \
    "Name=status,Values=available" \
  --query 'Volumes[*].{
    ID:VolumeId,
    Name:Tags[?Key==`Name`]|[0].Value,
    Size:Size,
    AZ:AvailabilityZone,
    Created:CreateTime
  }' \
  --output text

