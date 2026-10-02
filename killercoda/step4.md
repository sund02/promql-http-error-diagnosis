# Localize the failure with error ratios

You know something is failing. Now measure how bad it is and find where it
is, using only PromQL. Wait about a minute after step 3 before reading the
numbers, so the 1-minute query window is filled with failure-time data.

Run each query in the [Prometheus UI]({{TRAFFIC_HOST1_9090}}). Use the
**Table** tab for the current value and the **Graph** tab to see how it moved.

## 1. Overall error ratio

```
sum(rate(http_requests_total{status=~"5.."}[1m]))
/
sum(rate(http_requests_total[1m]))
```

Expected result: a single value around `0.2` (20% of all requests fail).

`rate(...[1m])` turns the ever-growing counters into requests per second over
the last minute. Dividing failed requests per second by all requests per second
gives the fraction of requests that fail.

## 2. Error ratio per endpoint

```
sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m]))
/
sum by (endpoint) (rate(http_requests_total[1m]))
```

Expected result:

```
{endpoint="/payments"}   1
```

`/payments` is failing every request. `/orders` is missing from the result
because it has no `5..` series, and PromQL division only keeps label sets that
exist on both sides. To show it explicitly as 0, fill in the gap with `or`:

```
(
  sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m]))
  or
  sum by (endpoint) (rate(http_requests_total[1m])) * 0
)
/
sum by (endpoint) (rate(http_requests_total[1m]))
```

Expected result:

```
{endpoint="/orders"}     0
{endpoint="/payments"}   1
```

## 3. Explain the gap: traffic per endpoint

```
sum by (endpoint) (rate(http_requests_total[1m]))
```

Expected result: about `8` for `/orders` and `2` for `/payments`.

## 4. Try a partial failure

Real incidents are rarely all-or-nothing. Make 30% of `/payments` requests
fail:

```
curl -s -X POST 'localhost:8000/admin/fail?rate=0.3'
```{{exec}}

Expected output:

```
{"failing":"/payments","rate":0.3}
```

After about a minute, rerun queries 1 and 2. The per-endpoint ratio for
`/payments` settles near `0.3`, while the overall ratio drops to about `0.06`.

## How aggregation hides a failing endpoint

The overall ratio is a traffic-weighted average. `/payments` gets only 20% of
the requests, so even a total outage of that endpoint shows up as a 20% overall
error ratio, and a 30% partial failure shows up as about 6%. If `/payments`
carried 1% of the traffic, a complete outage would read as 1% overall, below
many alert thresholds, while every customer trying to pay gets an error.

Low-traffic endpoints such as payments or login are often the ones that matter
most. Grouping `by (endpoint)` removes the averaging and points straight at the
broken component. Use the aggregate to notice that something is wrong, then
break it down by a label to find out where.

Grouping only works for labels the app exposes. This app labels by `endpoint`
and `status` and nothing else, which keeps the number of series small and
predictable. Labels such as user ID or full URL would let you slice further,
but they create a new series per value and can overload Prometheus.
