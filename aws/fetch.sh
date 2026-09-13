#!/usr/bin/env bash
# Pulls a finished run back into the local checkouts, then terminates the instance when TERMINATE=1.
set -euo pipefail
cd "$(dirname "$0")"
read -r INSTANCE_ID HOST < .last-instance
REGION="${AWS_REGION:-us-east-1}"
LOCAL_ROOT="$(cd ../.. && pwd)"

STATUS=$(ssh -o StrictHostKeyChecking=accept-new "ubuntu@$HOST" 'cat RUN_STATUS 2>/dev/null || echo RUNNING')
echo "remote status: $STATUS"
if [ "$STATUS" != "RUN_OK" ]; then
  echo "not fetching: a smoke test or an unfinished or failed run"
  [ "${TERMINATE:-0}" = "1" ] && aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" >/dev/null && echo "terminated $INSTANCE_ID"
  exit 1
fi

rsync -az --info=progress2 --exclude .git --exclude .snakemake \
  "ubuntu@$HOST:tehillim/tehillim-data/" "$LOCAL_ROOT/tehillim-data/"
rsync -az --info=progress2 "ubuntu@$HOST:tehillim/tehillim/public/data/" "$LOCAL_ROOT/tehillim/public/data/"
rsync -az --info=progress2 "ubuntu@$HOST:tehillim/tehillim/detail-data/" "$LOCAL_ROOT/tehillim/detail-data/"
echo "fetched. parity report: $LOCAL_ROOT/tehillim-data/_manifest.json"

if [ "${TERMINATE:-0}" = "1" ]; then
  aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" >/dev/null
  echo "terminated $INSTANCE_ID"
fi
