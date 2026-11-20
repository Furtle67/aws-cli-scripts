aws ec2 describe-regions --profile default --region us-east-1  | jq '.[]|.[]|.RegionName'
echo "nphase"
aws ec2 describe-regions  --profile nphase --region us-east-1  | jq '.[]|.[]|.RegionName'
echo "pfizer"
aws ec2  describe-regions --profile pfizer --region us-east-1   | jq '.[]|.[]|.RegionName'

