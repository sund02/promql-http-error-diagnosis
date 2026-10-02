#!/bin/bash
: '
Passes when failure injection is disabled and Prometheus returns at least one
per-endpoint error ratio, with every ratio exactly zero in the one-minute
window. An empty result or NaN (no traffic) fails the check.
'
set -uo pipefail

curl -sf http://localhost:8000/admin/status | grep -q '"failing":null' || exit 1

QUERY='sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m])) / sum by (endpoint) (rate(http_requests_total[1m]))'

curl -sfG http://localhost:9090/api/v1/query --data-urlencode "query=${QUERY}" \
  | python3 -c '
import json, sys
values = [float(series["value"][1]) for series in json.load(sys.stdin)["data"]["result"]]
sys.exit(0 if values and all(value == 0 for value in values) else 1)
'
