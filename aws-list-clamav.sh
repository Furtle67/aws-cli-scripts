profile="pfizer"; region="us-east-1"


# Build an instance-id -> Name tag lookup (one call, into an associative array)
declare -A NAME
while IFS=$'\t' read -r id name; do
  NAME["$id"]="$name"
done < <(aws ec2 describe-instances --profile $profile --region $region \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`]|[0].Value]' \
  --output text)

printf "%-22s %-28s %-20s %s\n" "INSTANCE" "NAME" "PACKAGE" "VERSION"
printf "%-22s %-28s %-20s %s\n" "--------" "----" "-------" "-------"

for id in $(aws ssm describe-instance-information --profile $profile --region $region \
              --query 'InstanceInformationList[].InstanceId' --output text); do

  iname="${NAME[$id]:-"(no name tag)"}"

  rows=$(aws ssm list-inventory-entries --instance-id "$id" \
    --type-name "AWS:Application" --profile $profile --region $region \
    --query "Entries[?contains(Name,'clam')].[Name,Version]" --output text)

  if [ -z "$rows" ]; then
    printf "%-22s %-28s %-20s %s\n" "$id" "$iname" "(none)" "NOT FOUND"
  else
    echo "$rows" | while IFS=$'\t' read -r name ver; do
      printf "%-22s %-28s %-20s %s\n" "$id" "$iname" "$name" "$ver"
    done
  fi
done


