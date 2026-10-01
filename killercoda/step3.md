# Inject a failure

So far every request has succeeded. Now you will break one endpoint on purpose
and see what changes in the metrics.

## 1. Check the current failure state

```
curl -s localhost:8000/admin/status
```{{exec}}

Expected output:

```
{"failing":null,"rate":null}
```

## 2. Make `/payments` return HTTP 500

```
curl -s -X POST localhost:8000/admin/fail
```{{exec}}

Expected output:

```
{"failing":"/payments","rate":1.0}
```

With no parameters, the app fails the endpoint set in `FAIL_ENDPOINT`
(`/payments` in `docker-compose.yml`) for every request (`rate` 1.0).

## 3. Confirm only `/payments` is broken

```
curl -s -o /dev/null -w '/payments -> %{http_code}\n' localhost:8000/payments
curl -s -o /dev/null -w '/orders   -> %{http_code}\n' localhost:8000/orders
```{{exec}}

Expected output:

```
/payments -> 500
/orders   -> 200
```

## 4. Confirm `/metrics` is still healthy

```
curl -s -o /dev/null -w '/metrics -> %{http_code}\n' localhost:8000/metrics
curl -s localhost:8000/metrics | grep '^http_requests_total{'
```{{exec}}

Expected output (counts will differ):

```
/metrics -> 200
http_requests_total{endpoint="/orders",status="200"} 4180.0
http_requests_total{endpoint="/payments",status="200"} 1046.0
http_requests_total{endpoint="/payments",status="500"} 38.0
```

A new series with `status="500"` has appeared, and the traffic generator keeps
adding to it.

## 5. Find the new series in Prometheus

Open the [Prometheus UI]({{TRAFFIC_HOST1_9090}}) and run:

```
http_requests_total{status="500"}
```

Expected result: one series, `{endpoint="/payments", status="500", ...}`,
whose value grows on each refresh. It can take up to 5 seconds (one scrape
interval) to show up.

## Why the target still looks healthy

The failure breaks the business endpoint, not the monitoring path. Many
production incidents look like this. The process is alive, Prometheus can
still scrape it, and the target stays `up`. A plain "is it up?" check would report
everything as fine. The problem is only visible in what the metrics say about
the requests being served.

Notice also that the `status="500"` series did not exist before the first
failed request. Prometheus has no data for a label combination until the app
reports it. In the next step this matters: a ratio query returns nothing,
rather than 0, for an endpoint that has never failed.
