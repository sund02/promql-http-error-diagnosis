# Observe healthy traffic

The traffic generator has been sending requests since the environment
started. In this step you record what normal looks like, so you can recognize
the failure later.

## 1. See the traffic generator at work

```
docker compose logs --tail 5 trafficgen
```{{exec}}

Expected result: summary lines showing successful requests to `/orders` and
`/payments`, and no errors.

## 2. Query the raw counters

Open the [Prometheus UI]({{TRAFFIC_HOST1_9090}}) and run:

```
http_requests_total
```

Expected result: two series, one per endpoint, both with `status="200"`.
Execute the query again after a few seconds and the values will have grown.

A counter only goes up, and it restarts from zero when the app restarts. Its
raw value is the total since the app started, which says little about what is
happening right now.

## 3. Turn counters into request rates

```
rate(http_requests_total[1m])
```

Expected result: the same two series, now as requests per second averaged
over the last minute. Switch to the **Graph** tab to see two flat lines.

Add the series up per endpoint:

```
sum by (endpoint) (rate(http_requests_total[1m]))
```

Expected result:

```
{endpoint="/orders"}     8
{endpoint="/payments"}   2
```

The values will wobble slightly around 8 and 2.

## 4. Check latency

```
histogram_quantile(0.95, sum by (le, endpoint) (rate(http_request_duration_seconds_bucket[1m])))
```

Expected result: about `0.05` for both endpoints. 95% of requests finish in
about 50 ms or less.

## Why record a baseline

Write down the two numbers from step 3: about 8 requests per second for `/orders`
and 2 for `/payments`, all with status 200.

`rate()` is the function you will use for the rest of the tutorial. It takes
the samples of a counter inside the window, here `[1m]`, and computes the
per-second increase, handling counter resets on the way. With a 5-second
scrape interval, a 1-minute window holds about 12 samples, enough for a stable
value that still reacts within a minute.

Keep the uneven traffic in mind. `/payments` gets only a fifth of the requests,
and that will matter in step 4.
