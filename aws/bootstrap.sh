#!/usr/bin/env bash
# EC2 user data: clones the project, builds its venvs, runs the driver with every benchmark cell forced.
set -euo pipefail

GITHUB_TOKEN="__GITHUB_TOKEN__"
CELLS_AT_ONCE="__CELLS_AT_ONCE__"
WORKERS_PER_CELL="__WORKERS_PER_CELL__"
# When set, only these rules run and RUN_STATUS reports SMOKE_OK: the environment check before a full run.
SMOKE_RULES="__SMOKE_RULES__"
RUN_USER=ubuntu
HOME_DIR=/home/$RUN_USER
ROOT=$HOME_DIR/tehillim
LOG=$HOME_DIR/bootstrap.log

exec > >(tee -a "$LOG") 2>&1
echo "bootstrap start $(date -u +%FT%TZ)"

apt-get update -y
apt-get install -y python3.12 python3.12-venv python3-pip git rsync

sudo -u $RUN_USER -H env GITHUB_TOKEN="$GITHUB_TOKEN" ROOT="$ROOT" HOME_DIR="$HOME_DIR" \
  CELLS_AT_ONCE="$CELLS_AT_ONCE" WORKERS_PER_CELL="$WORKERS_PER_CELL" SMOKE_RULES="$SMOKE_RULES" \
  bash -euo pipefail <<'USER'
export GHPERS="$GITHUB_TOKEN"
mkdir -p "$ROOT" "$HOME_DIR/Developer/hebrew" "$HOME_DIR/text-fabric-data/github/rdtaylorjr/tehillim-logos/tf"
cd "$ROOT"
for repo in tehillim-embeddings tehillim-benchmark tehillim-data tehillim-logos tehillim; do
  [ -d "$repo" ] || git clone --depth 1 "https://$GITHUB_TOKEN@github.com/rdtaylorjr/$repo.git" "$repo"
done

# BHSA 2021 from the ETCBC, the checkout the loaders read from disk before falling back to a download.
if [ ! -d "$HOME_DIR/Developer/hebrew/bhsa" ]; then
  git clone --depth 1 --filter=blob:none --sparse https://github.com/ETCBC/bhsa.git "$HOME_DIR/Developer/hebrew/bhsa"
  git -C "$HOME_DIR/Developer/hebrew/bhsa" sparse-checkout set tf/2021
fi
# The Logos module where Text-Fabric caches it, from the checkout that publishes it.
cp -R "$ROOT/tehillim-logos/tf/2021" "$HOME_DIR/text-fabric-data/github/rdtaylorjr/tehillim-logos/tf/"

cd "$ROOT/tehillim-embeddings" && python3.12 -m venv .venv && .venv/bin/pip install -q -e "."
cd "$ROOT/tehillim-benchmark" && python3.12 -m venv .venv && .venv/bin/pip install -q -e ".[dev]" -e ../tehillim-embeddings

cd "$ROOT/tehillim-data"
SNAKEMAKE=../tehillim-benchmark/.venv/bin/snakemake
# The checked-out tree predates the driver, so its outputs are registered before anything is forced.
$SNAKEMAKE --touch --forceall --keep-going --rerun-triggers params -j 1 --config workers="$WORKERS_PER_CELL" || true
echo "run start $(date -u +%FT%TZ)"
if [ -n "$SMOKE_RULES" ]; then
  if $SNAKEMAKE -j "$CELLS_AT_ONCE" --rerun-triggers params --config workers="$WORKERS_PER_CELL" \
       --forcerun $SMOKE_RULES -- $SMOKE_RULES; then
    echo SMOKE_OK > "$HOME_DIR/RUN_STATUS"
  else
    echo SMOKE_FAILED > "$HOME_DIR/RUN_STATUS"
  fi
else
  BENCHMARK_RULES=$($SNAKEMAKE --list-target-rules 2>/dev/null | grep '^benchmark_cell__' | tr '\n' ' ')
  if $SNAKEMAKE -j "$CELLS_AT_ONCE" --rerun-triggers params --keep-going \
       --config workers="$WORKERS_PER_CELL" --forcerun $BENCHMARK_RULES; then
    echo RUN_OK > "$HOME_DIR/RUN_STATUS"
  else
    echo RUN_FAILED > "$HOME_DIR/RUN_STATUS"
  fi
fi
echo "run end $(date -u +%FT%TZ) status $(cat "$HOME_DIR/RUN_STATUS")"
USER

echo "bootstrap end $(date -u +%FT%TZ)"
