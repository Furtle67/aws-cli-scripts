aws  logs describe-log-groups \
  --profile nphase \
  --region us-east-1 \
  --query "logGroups[*].logGroupName" \
  | jq -r '.[]' \
 | grep -E 'containerinsight|eks' \

