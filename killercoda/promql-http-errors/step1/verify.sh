#!/bin/bash
: '
Passes when Prometheus reports the app scrape target as healthy.
'
set -uo pipefail

curl -sf http://localhost:9090/api/v1/targets | python3 -c '
import json, sys
targets = json.load(sys.stdin)["data"]["activeTargets"]
sys.exit(0 if any(t["labels"].get("job") == "app" and t["health"] == "up" for t in targets) else 1)
'
