#!/bin/bash
: '
Passes when failure injection is disabled and no per-endpoint error ratio is
greater than zero in the one-minute query window.
'
set -uo pipefail

curl -sf http://localhost:8000/admin/status | grep -q '"failing":null' || exit 1

QUERY='sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m])) / sum by (endpoint) (rate(http_requests_total[1m]))'

curl -sfG http://localhost:9090/api/v1/query --data-urlencode "query=${QUERY}" \
  | python3 -c '
import json, sys
result = json.load(sys.stdin)["data"]["result"]
sys.exit(1 if any(float(series["value"][1]) > 0 for series in result) else 0)
'
