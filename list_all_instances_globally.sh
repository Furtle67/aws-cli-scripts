#####
# loop through and record all instances ids 
#  script to record and help locate instance vs id
#  for auto-created karepenter nodes
#
# (cheaper than using CloudTrail and athena in the short run)
#
#  ##

cd /home/ablazey/Projects/furtle67/aws-cli-scripts

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

#remove duplicates to reduce size
#  add the new lines to the old lines
cat sorted_instances.tsv instances.tsv >temp_instances.tsv
#remove duplicates.
sort -u temp_instances.tsv >sorted_instances.tsv
#clean
rm temp_instances.tsv
