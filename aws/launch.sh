#!/usr/bin/env bash
# Launches one spot (default) or on-demand instance that runs aws/bootstrap.sh and leaves results on disk.
set -euo pipefail
cd "$(dirname "$0")"

: "${GITHUB_TOKEN:?set GITHUB_TOKEN to a token that can read the rdtaylorjr repositories}"
: "${KEY_NAME:?set KEY_NAME to the EC2 key pair used for ssh}"
# SMOKE=1 runs two real cells on a 4-vCPU instance to prove the environment before a full run.
SMOKE="${SMOKE:-0}"
SMOKE_RULES=""
if [ "$SMOKE" = "1" ]; then
  INSTANCE_TYPE="${INSTANCE_TYPE:-c7i.xlarge}"
  WORKERS_PER_CELL="${WORKERS_PER_CELL:-4}"
  SMOKE_RULES="benchmark_cell__parallelism_syntactic_baseline benchmark_cell__genre_lexical_gunkel_song_calibrated"
fi
INSTANCE_TYPE="${INSTANCE_TYPE:-c7i.48xlarge}"
MARKET="${MARKET:-spot}"
REGION="${AWS_REGION:-us-east-1}"
VOLUME_GB="${VOLUME_GB:-100}"
WORKERS_PER_CELL="${WORKERS_PER_CELL:-8}"
# Published outputs are adopted as they are; rules matching this regex are recomputed regardless.
FORCE_PATTERN="${FORCE_PATTERN:-benchmark_cell__genre_.*_gunkel_}"

VCPUS=$(aws ec2 describe-instance-types --region "$REGION" --instance-types "$INSTANCE_TYPE" \
  --query 'InstanceTypes[0].VCpuInfo.DefaultVCpus' --output text)
CELLS_AT_ONCE=$(( VCPUS / WORKERS_PER_CELL ))

AMI=$(aws ssm get-parameter --region "$REGION" \
  --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id \
  --query Parameter.Value --output text)

MY_IP=$(curl -s https://checkip.amazonaws.com)
SG_NAME=tehillim-driver
SG_ID=$(aws ec2 describe-security-groups --region "$REGION" --filters "Name=group-name,Values=$SG_NAME" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  SG_ID=$(aws ec2 create-security-group --region "$REGION" --group-name "$SG_NAME" \
    --description "ssh from the launching machine" --query GroupId --output text)
fi
aws ec2 authorize-security-group-ingress --region "$REGION" --group-id "$SG_ID" \
  --protocol tcp --port 22 --cidr "$MY_IP/32" >/dev/null 2>&1 || true

USER_DATA=$(sed -e "s|__GITHUB_TOKEN__|$GITHUB_TOKEN|" -e "s|__CELLS_AT_ONCE__|$CELLS_AT_ONCE|" \
  -e "s|__WORKERS_PER_CELL__|$WORKERS_PER_CELL|" -e "s|__SMOKE_RULES__|$SMOKE_RULES|" \
  -e "s|__FORCE_PATTERN__|$FORCE_PATTERN|" bootstrap.sh)

MARKET_OPTIONS=()
if [ "$MARKET" = "spot" ]; then
  MARKET_OPTIONS=(--instance-market-options 'MarketType=spot,SpotOptions={SpotInstanceType=one-time,InstanceInterruptionBehavior=terminate}')
fi

INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" \
  --image-id "$AMI" --instance-type "$INSTANCE_TYPE" --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$VOLUME_GB,\"VolumeType\":\"gp3\"}}]" \
  --user-data "$USER_DATA" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=tehillim-driver}]' \
  ${MARKET_OPTIONS[@]+"${MARKET_OPTIONS[@]}"} \
  --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"
HOST=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicDnsName' --output text)
echo "instance $INSTANCE_ID ($INSTANCE_TYPE, $MARKET, $VCPUS vCPU, $CELLS_AT_ONCE cells x $WORKERS_PER_CELL workers)"
echo "ssh ubuntu@$HOST   # tail -f bootstrap.log for the step count, tehillim/tehillim-data/logs/<cell>.log for a cell"
echo "progress: ssh ubuntu@$HOST 'grep -c Finished bootstrap.log; grep -h ^progress tehillim/tehillim-data/logs/*.log | tail'"
echo "$INSTANCE_ID $HOST" > .last-instance
