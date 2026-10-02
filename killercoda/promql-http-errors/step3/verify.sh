#!/bin/bash
: '
Passes when failure injection is active and Prometheus has scraped at least
one 5xx series from the app.
'
set -uo pipefail

curl -sf http://localhost:8000/admin/status | grep -q '"failing":"/' || exit 1

curl -sfG http://localhost:9090/api/v1/query \
  --data-urlencode 'query=http_requests_total{status=~"5.."}' \
  | grep -q '"endpoint"'
