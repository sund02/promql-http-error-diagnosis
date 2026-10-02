# Recover and watch the error ratio drop

The failure is active at either 30% or 100% for `/payments`. Recover the app,
then observe the difference between the service state and the metric window.

## 1. Recover the app

```
curl -s -X POST localhost:8000/admin/recover
```{{exec}}

Expected output:

```
{"failing":null,"rate":null}
```

## 2. Confirm the current state

```
curl -s -o /dev/null -w '/payments -> %{http_code}\n' localhost:8000/payments
```{{exec}}

Expected output:

```
/payments -> 200
```

```
curl -s localhost:8000/admin/status
```{{exec}}

Expected output:

```
{"failing":null,"rate":null}
```

## 3. Watch the one-minute ratio recover

Open the [Prometheus UI]({{TRAFFIC_HOST1_9090}}) and run:

```
sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m]))
/
sum by (endpoint) (rate(http_requests_total[1m]))
```

Expected result: the `/payments` ratio falls gradually from about `1` or
`0.3`, then reaches `0` about one minute after recovery. `/payments` stays in
the result as `0` because the `status="500"` series still exists but has
stopped increasing.

Press **Check** once the ratio shows `0`. Pressed earlier, the check fails
because the failures are still inside the 1-minute window.

Open the **Graph** tab and select a 10-minute range. The incident appears as a
plateau followed by a ramp down.

## 4. Try a longer query window

Optionally, rerun the query with a five-minute window:

```
sum by (endpoint) (rate(http_requests_total{status=~"5.."}[5m]))
/
sum by (endpoint) (rate(http_requests_total[5m]))
```

Expected result: the ratio takes longer to reach `0` because the query keeps
more of the incident in its window.

## 5. Confirm the failure counter stopped

Read the failure counter twice, five seconds apart:

```
curl -s localhost:8000/metrics | grep '^http_requests_total{.*status="500"'
sleep 5
curl -s localhost:8000/metrics | grep '^http_requests_total{.*status="500"'
```{{exec}}

Expected output (your count will differ, but both lines show the same value):

```
http_requests_total{endpoint="/payments",status="500"} 300.0
http_requests_total{endpoint="/payments",status="500"} 300.0
```

Healthy traffic continues, but no failed request increments the counter any
more.

## Why the ratio lags behind the fix

The fix is instant, but the ratio can lag by up to the query window plus one
scrape interval, about 1 min + 5 s here. `rate()` averages the
counter increase over the selected window, so recent failures remain part of
the calculation until the window moves past them. Shorter windows react
faster but are noisier. Any alert built on this query inherits the same delay.
