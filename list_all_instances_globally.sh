#####
# loop through and record all instances ids 
#  script to record and help locate instance vs id
#  for auto-created karepenter nodes
#
# (cheaper than using CloudTrail and athena in the short run)
#
#  ##

#loop aws profiles
for profile in $(aws configure list-profiles); do
  echo "--- Profile: $profile ---"
  export AWS_DEFAULT_PROFILE=$profile
  echo $AWS_DEFAULT_PROFILE
      #loop regions
     for region in $(aws account list-regions --query 'Regions[*].RegionName' --output text); do
         echo "-- Region: $region  ---"
         #get current instances in region and record in tsv
         aws ec2 describe-instances   --region $region   --output text   --query 'Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PrivateIpAddress, PublicIpAddress, LaunchTime]' >>instances.tsv 2>/dev/null
     done
done
