#!/bin/bash
: '
Prepares the scenario environment unattended: clones the tutorial repo, starts
the compose stack and waits until Prometheus reports the app target as up.
All output goes to /tmp/setup.log. Creates /tmp/.setup-done on success and
/tmp/.setup-failed on any error or timeout; foreground.sh waits for either.
'
set -Eeuo pipefail
exec > /tmp/setup.log 2>&1
trap 'touch /tmp/.setup-failed' ERR

REPO_URL="https://github.com/sund02/promql-http-error-diagnosis.git"
WORKDIR="/root/promql-tutorial"
COMPOSE_VERSION="v2.29.7"
WAIT_SECONDS=240

wait_for() {
  : 'Retry the given command every 2 s; fail after WAIT_SECONDS.'
  local deadline=$((SECONDS + WAIT_SECONDS))
  until "$@" >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      echo "Timed out waiting for: $*"
      return 1
    fi
    sleep 2
  done
}

app_target_up() {
  curl -sf http://localhost:9090/api/v1/targets | grep -q '"health":"up"'
}

if ! docker compose version >/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
fi

git clone --depth 1 "$REPO_URL" "$WORKDIR"
cd "$WORKDIR"
docker compose up -d --build

wait_for curl -sf http://localhost:9090/-/ready
wait_for app_target_up

touch /tmp/.setup-done
