#!/bin/bash
echo "Starting the app, traffic generator and Prometheus. This takes about a minute..."
SECONDS=0; while [ ! -f /tmp/.setup-done ] && [ ! -f /tmp/.setup-failed ] && [ "$SECONDS" -lt 420 ]; do sleep 2; done
if [ -f /tmp/.setup-done ]; then cd /root/promql-tutorial; clear; echo "Environment ready. You are in /root/promql-tutorial."; else echo "Setup did not finish. Last lines of /tmp/setup.log:"; tail -n 20 /tmp/setup.log 2>/dev/null; echo "Restart the scenario to try again."; fi
