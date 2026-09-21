#!/bin/bash

echo "-----------------------------------------------------------"
printf "%-40s %-12s %-10s %-15s %s\n" "BUCKET" "LOCK" "MODE" "RETENTION" "VERSIONING"
echo "-----------------------------------------------------------"

for bucket in $(aws --profile nphase s3api list-buckets --query 'Buckets[*].Name' --output text); do

    # Get versioning status
    versioning=$(aws s3api get-bucket-versioning \
        --bucket "$bucket" \
        --query 'Status' --output text 2>/dev/null)
    versioning=${versioning:-Disabled}

    # Get object lock configuration
    lock_config=$(aws s3api get-object-lock-configuration \
        --bucket "$bucket" 2>/dev/null)

    if [ -z "$lock_config" ]; then
        printf "%-40s %-12s %-10s %-15s %s\n" \
            "$bucket" "DISABLED" "-" "-" "$versioning"
    else
        lock_enabled=$(echo "$lock_config" | jq -r \
            '.ObjectLockConfiguration.ObjectLockEnabled // "Disabled"')
        mode=$(echo "$lock_config" | jq -r \
            '.ObjectLockConfiguration.Rule.DefaultRetention.Mode // "-"')
        days=$(echo "$lock_config" | jq -r \
            '.ObjectLockConfiguration.Rule.DefaultRetention.Days // ""')
        years=$(echo "$lock_config" | jq -r \
            '.ObjectLockConfiguration.Rule.DefaultRetention.Years // ""')

        # Build retention string
        if [ -n "$days" ] && [ "$days" != "null" ]; then
            retention="${days}d"
        elif [ -n "$years" ] && [ "$years" != "null" ]; then
            retention="${years}y"
        else
            retention="No default"
        fi

        printf "%-40s %-12s %-10s %-15s %s\n" \
            "$bucket" "$lock_enabled" "$mode" "$retention" "$versioning"
    fi
done

