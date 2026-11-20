# AWS Useful Commands

## Contents

- [General](#general)
- [EC2 / SSM Patching](#ec2--ssm-patching)
- [EC2 Instance Metadata (IMDS)](#ec2-instance-metadata-imds)
- [IPA / LDAP](#ipa--ldap)
- [VPC Endpoints & PrivateLink Traffic](#vpc-endpoints--privatelink-traffic)
- [CloudTrail](#cloudtrail)
- [CloudWatch](#cloudwatch)
- [EKS / Kubernetes](#eks--kubernetes)
- [IAM](#iam)
- [RDS](#rds)
- [SSM Inventory](#ssm-inventory)

---

## General

Format an epoch timestamp as a date:

```bash
date -u -d @$((1789214582 )) +%Y-%m-%d
```

List enabled regions:

```bash
aws account list-regions --region-opt-status-contains ENABLED
```

---

## EC2 / SSM Patching

Show patches on an EC2 instance:

```bash
aws ssm describe-instance-patches --profile pfizer --region us-east-1  --instance-id i-07215d688b8d199ae  --output table
```

Show patch commands run (last 30 days):

```bash
aws ssm list-command-invocations --profile pfizer --region us-east-1   --query 'CommandInvocations[].[InstanceId,RequestedDateTime,Status]'   --output table
```

---

## EC2 Instance Metadata (IMDS)

Check IMDS settings (HttpTokens / HttpEndpoint) and state:

```bash
aws ec2 describe-instances --profile nphase --region us-east-1   --query 'Reservations[].Instances[].[InstanceId,MetadataOptions.HttpTokens,MetadataOptions.HttpEndpoint,State.Name]'   --output table
```

HttpTokens only:

```bash
aws ec2 describe-instances --profile nphase --region us-east-1   --query 'Reservations[].Instances[].[InstanceId,MetadataOptions.HttpTokens]'   --output table
```

---

## IPA / LDAP

Find user in IPA from SSH key fingerprint:

```bash
ldapsearch -Y GSSAPI -H ldaps://mgt-nv-ipa-01.redcapcloud.local   -b "cn=users,cn=accounts,dc=REDCAPCLOUD,dc=LOCAL"   "(ipaSshPubKeyFingerprint=*NOcQ30Wzbyypz+xwkg93Lb8yTgM7Ifjo34cAGURMBys*)"   uid ipaSshPubKeyFingerprint
```

---

## VPC Endpoints & PrivateLink Traffic

List VPC endpoints:

```bash
aws ec2 describe-vpc-endpoints --profile nphase --region us-east-1   --query 'VpcEndpoints[].[VpcEndpointId,ServiceName,VpcEndpointType,State]'   --output table
```

### usuat / stjude — `vpce-svc-0893799292149500b`

Daily bytes processed:

```bash
aws cloudwatch get-metric-statistics   --namespace AWS/PrivateLinkServices   --metric-name BytesProcessed   --dimensions "Name=Service Id,Value=vpce-svc-0893799292149500b"   --start-time '2026-09-01'   --end-time  '2026-09-30'   --period 86400 --statistics Sum   --profile nphase --region us-east-1   --query 'Datapoints | sort_by(@,&Timestamp)[].[Timestamp,Sum]' --output table
```

Total for period in GB (PowerShell):

```powershell
$bytes=aws cloudwatch get-metric-statistics --profile nphase --region us-east-1  --namespace AWS/PrivateLinkServices     --metric-name BytesProcessed  --dimensions "Name=Service Id,Value=vpce-svc-0893799292149500b" --start-time  '2026-09-01'   --end-time '2026-09-30'  --period 86400 --statistics Sum  --query 'sum(Datapoints[].Sum)' --output text
($bytes / 1024 / 1024 /1024)
```

### usproduction / stjude — `vpce-svc-070eda885b8576f20`

Daily bytes processed:

```bash
aws cloudwatch get-metric-statistics   --namespace AWS/PrivateLinkServices   --metric-name BytesProcessed   --dimensions "Name=Service Id,Value=vpce-svc-070eda885b8576f20"   --start-time '2026-09-01'   --end-time  '2026-09-30'   --period 86400 --statistics Sum   --profile nphase --region us-east-1   --query 'Datapoints | sort_by(@,&Timestamp)[].[Timestamp,Sum]' --output table
```

Total for period in GB (PowerShell):

```powershell
$bytes=aws cloudwatch get-metric-statistics --profile nphase --region us-east-1  --namespace AWS/PrivateLinkServices     --metric-name BytesProcessed  --dimensions "Name=Service Id,Value=vpce-svc-070eda885b8576f20" --start-time  '2026-09-01'   --end-time '2026-09-30'  --period 86400 --statistics Sum  --query 'sum(Datapoints[].Sum)' --output text
($bytes / 1024 / 1024 /1024)
```

---

## CloudTrail

Look up events for a resource (PowerShell):

```powershell
$env:AWS_PROFILE = "pfizer"
$env:AWS_REGION ="us-east-1"
aws cloudtrail lookup-events   --lookup-attributes AttributeKey=ResourceName,AttributeValue=i-0fe9cf74cb5ddce6f   --start-time 2026-06-15T00:00:00Z   --end-time   2026-06-16T23:59:59Z
```

Same, in bash:

```bash
export AWS_PROFILE="pfizer"
export AWS_REGION="us-east-1"
aws cloudtrail lookup-events   --lookup-attributes AttributeKey=ResourceName,AttributeValue=i-0fe9cf74cb5ddce6f   --start-time 2026-06-15T00:00:00Z   --end-time   2026-06-16T23:59:59Z
```

Parse saved events with jq:

```bash
jq -r '.[]|.[]|.EventName,.EventId,.EventName,.EventTime,.EventSource,.Username' kafka_down_node_events.json
```

Find `RunInstances` events launched by EKS Auto Mode:

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances \
  --start-time 2026-06-14T00:00:00Z \
  --end-time   2026-06-22T23:59:59Z \
  --max-items 500 \
  --query 'Events[?contains(Username, `eks-auto-mode-compute`)].[EventTime,Username,Resources[?ResourceType==`AWS::EC2::Instance`]|[0].ResourceName]' \
  --output table
```

---

## CloudWatch

EC2 CPU utilisation (5-min average):

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0fe9cf74cb5ddce6f \
  --start-time 2026-06-15T00:00:00Z \
  --end-time 2026-06-18T00:05:00Z \
  --period 300 \
  --statistics Average
```

---

## EKS / Kubernetes

NodePool disruption settings:

```bash
kubectl get nodepool -o custom-columns='NAME:.metadata.name,EXPIRE_AFTER:.spec.disruption.expireAfter,CONSOLIDATION:.spec.disruption.consolidationPolicy,CONSOLIDATE_AFTER:.spec.disruption.consolidateAfter'
```

Pod restarts / node placement:

```bash
kubectl get pods -n pfeprod-exec -o custom-columns='NAME:.metadata.name,NODE:.spec.nodeName,RESTARTS:.status.containerStatuses[*].restartCount,LAST_STATE:.status.containerStatuses[*].lastState,STARTED:.status.containerStatuses[*].state.running.startedAt,AGE:.metadata.creationTimestamp'
```

CloudWatch Logs Insights — evictions / memory or disk pressure in EKS audit logs:

```bash
aws logs start-query   --log-group-name /aws/eks/pfeprod-exec-nv-eks/cluster   --start-time $(date -d '2026-06-15T01:30:00' +%s)   --end-time   $(date -d '2026-06-15T03:00:00' +%s)   --query-string 'fields @timestamp, @message                  | filter @logStream like /audit/                    and (@message like /Evicted/ or @message like /MemoryPressure/ or @message like /DiskPressure/)                  | sort @timestamp'
```

---

## IAM

Find IAM users missing `Email` / `EmailUser` tags:

```bash
aws --profile nphase iam list-users | jq '.Users[].UserName' | while read user; do
  tags=$(aws iam list-user-tags --user-name $user | jq '.Tags')
  email=$(echo $tags | jq -r '.[] | select(.Key=="Email") | .Value')
  emailuser=$(echo $tags | jq -r '.[] | select(.Key=="EmailUser") | .Value')
  if [ -z "$email" ] && [ -z "$emailuser" ]; then
    echo "MISSING TAGS: $user"
  fi
done
```

---

## RDS

List RDS Postgres versions:

```bash
aws rds describe-db-instances --profile nphase --region us-east-1   --query "DBInstances[?Engine=='postgres'].[DBInstanceIdentifier,EngineVersion,DBInstanceClass]"   --output table
```

---

## SSM Inventory

For EC2 connected to SSM, return instances with an installed app (OS layer only — cannot check containers).

> Note: EKS nodes are currently not connected to SSM and likely never will be.

nginx:

```bash
aws ssm get-inventory --region us-east-1 --filters "Key=AWS:Application.Name,Values=nginx,Type=BeginWith" --query 'Entities[].Id' --output text
```

haproxy (known-installed package — sanity check that inventory works):

```bash
aws ssm get-inventory --region us-east-1 --filters "Key=AWS:Application.Name,Values=haproxy,Type=BeginWith" --query 'Entities[].Id' --output text
```

Notes:

- In the AWS console, inventory is available per EC2 instance, but there is no option to check all instances at once.
- To check other accounts/regions, change the AWS CLI parameters (`--profile`, `--region`).
