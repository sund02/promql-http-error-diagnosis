#!/bin/bash
: '
Passes when Prometheus has a non-zero request rate for both /orders and
/payments, i.e. background traffic is flowing and being scraped.
'
set -uo pipefail

QUERY='sum by (endpoint) (rate(http_requests_total[1m]))'

curl -sfG http://localhost:9090/api/v1/query --data-urlencode "query=${QUERY}" \
  | python3 -c '
import json, sys
result = json.load(sys.stdin)["data"]["result"]
active = {s["metric"].get("endpoint") for s in result if float(s["value"][1]) > 0}
sys.exit(0 if {"/orders", "/payments"} <= active else 1)
'
