export AWS_DEFAULT_PROFILE=nphase
for region in $(aws account list-regions --query 'Regions[*].RegionName' --output text); do
echo $region
      	result=$(aws ec2 describe-instances \
    --instance-ids i-0879d4099cfab1273 \
    --region $region \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output text 2>/dev/null)
  if [ -n "$result" ]; then
    echo "Found in region: $region"
    echo "$result"
  fi
done



export AWS_DEFAULT_PROFILE=pfizer
for region in $(aws account list-regions --query 'Regions[*].RegionName' --output text); do
echo $region
  result=$(aws ec2 describe-instances \
    --instance-ids i-0879d4099cfab1273 \
    --region $region \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output text 2>/dev/null)
  if [ -n "$result" ]; then
    echo "Found in region: $region"
    echo "$result"
  fi
done

export AWS_DEFAULT_PROFILE=databricks
for region in $(aws account list-regions --query 'Regions[*].RegionName' --output text); do
echo $region
  result=$(aws ec2 describe-instances \
    --instance-ids i-0879d4099cfab1273 \
    --region $region \
    --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
    --output text 2>/dev/null)
  if [ -n "$result" ]; then
    echo "Found in region: $region"
    echo "$result"
  fi
done

