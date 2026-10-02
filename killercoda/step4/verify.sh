#!/bin/bash
: '
Passes when the per-endpoint error ratio from step 4 is above 0 for at least
one endpoint, i.e. the learner can localize the failure with PromQL.
'
set -uo pipefail

QUERY='sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m])) / sum by (endpoint) (rate(http_requests_total[1m]))'

curl -sfG http://localhost:9090/api/v1/query --data-urlencode "query=${QUERY}" \
  | python3 -c '
import json, sys
result = json.load(sys.stdin)["data"]["result"]
sys.exit(0 if any(float(series["value"][1]) > 0 for series in result) else 1)
'
