######
#  lists volumes that are avaialble (unused)
#  sorted by date and cost
#  same for snapshots.
#  ##

echo "nphase"

export AWS_REGION="us-west-2"
export AWS_PROFILE="nphase"

echo "unused  Volumes"
# pfizer
#
 aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'sort_by(Volumes,&CreateTime)[].[Tags[?Key==`Name`]|[0].Value,VolumeId,VolumeType,Size,CreateTime]' \
  --output table 
 #  | awk 'BEGIN{p["gp3"]=0.08;p["gp2"]=0.10;p["io1"]=0.125;p["io2"]=0.125;p["st1"]=0.045;p["sc1"]=0.015;p["standard"]=0.05}
#{cost=$3*p[$2]; total+=cost; printf "%-22s %-9s %5d GiB  %-25s $%6.2f/mo\n",$1,$2,$3,$4,cost}
#END{printf "\n%-22s %-9s %5d          %-25s $%6.2f/mo\n","TOTAL","","","",total}'



echo "Snapshots older than year"
cutoff=$(date -u -d '1 year ago' +%Y-%m-%dT%H:%M:%S)

aws ec2 describe-snapshots --owner-ids self \
  --query "sort_by(Snapshots[?StartTime<'${cutoff}'],&StartTime)[].[SnapshotId,VolumeId,StorageTier,FullSnapshotSizeInBytes,StartTime,Tags[?Key==\`Name\`]|[0].Value,Description]" \
  --output text



