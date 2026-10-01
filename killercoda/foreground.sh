#!/bin/bash
echo "Starting the app, traffic generator and Prometheus. This takes about a minute..."
while [ ! -f /tmp/.setup-done ]; do sleep 2; done
cd /root/promql-tutorial
clear
echo "Environment ready. You are in /root/promql-tutorial."
