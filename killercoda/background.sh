#!/bin/bash
: '
Prepares the scenario environment unattended: clones the tutorial repo, starts
the compose stack and waits until Prometheus reports the app target as up.
Creates /tmp/.setup-done when finished, which foreground.sh waits for.
'
set -euo pipefail

REPO_URL="https://github.com/sund02/promql-http-error-diagnosis.git"
WORKDIR="/root/promql-tutorial"
COMPOSE_VERSION="v2.29.7"

if ! docker compose version >/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

git clone --depth 1 "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"
docker compose up -d --build

until curl -sf http://localhost:9090/-/ready >/dev/null; do sleep 2; done
until curl -sf http://localhost:9090/api/v1/targets | grep -q '"health":"up"'; do sleep 2; done

touch /tmp/.setup-done
