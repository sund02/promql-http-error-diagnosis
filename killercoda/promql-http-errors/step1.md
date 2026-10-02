# Start the environment and verify scraping

The setup script has already started the app, a traffic generator and
Prometheus, each in its own container. Before running any query, check that
Prometheus is collecting the app's metrics.

## 1. Check the containers

```
cd /root/promql-tutorial
docker compose ps
```{{exec}}

Expected result: three services, `app`, `trafficgen` and `prometheus`, all
with status `Up`. The app also shows `(healthy)`.

## 2. Look at the raw metrics

```
curl -s localhost:8000/metrics | grep '^http_requests_total{'
```{{exec}}

Expected output (counts will differ):

```
http_requests_total{endpoint="/orders",status="200"} 412.0
http_requests_total{endpoint="/payments",status="200"} 104.0
```

This is the plain-text format Prometheus reads. Each line is one time series:
a metric name, a set of labels and the current value.

## 3. Confirm Prometheus scrapes the app

```
curl -s localhost:9090/api/v1/targets | grep -o '"health":"[a-z]*"'
```{{exec}}

Expected output:

```
"health":"up"
```

Now open the [Prometheus UI]({{TRAFFIC_HOST1_9090}}), go to
**Status → Targets**, and find the `app` job with state `UP` and a last
scrape a few seconds ago. Then run this query on the main page:

```
up{job="app"}
```

Expected result: `1`.

## Why check the pipeline first

Every query in this tutorial depends on Prometheus scraping the app every
5 seconds. Prometheus records the `up` series itself on each scrape: `1` when
it reached `/metrics`, `0` when it could not. If the target were down, later
queries would return no data at all, and an empty result is easy to misread as
"no errors". Once `up` is 1 you know the data is being collected. In this
tutorial an empty result then usually means the event has not happened, but a
mistyped label or a query window with too few samples can also return nothing.
Check the query before drawing conclusions.
