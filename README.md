# Diagnosing HTTP Service Errors with Prometheus and PromQL

An executable tutorial. You run a small instrumented HTTP service, break one of
its endpoints, and use PromQL error-ratio queries to find which endpoint is
failing. It runs as a guided Killercoda scenario in about 20 to 30 minutes, or
locally with Docker Compose.
![Architecture](docs/architecture.svg)

## Run locally

Requires Docker with the Compose plugin.

```
docker compose up -d --build
```

Then open the Prometheus UI at <http://localhost:9090> and check
**Status → Targets**: the `app` target should be `UP` within about 10 seconds.

Stop and remove everything:

```
docker compose down
```

## Services

| Service | Port | Purpose |
|---|---|---|
| `app` | 8000 | Flask service with `/orders`, `/payments`, `/metrics` and the failure controls |
| `trafficgen` | none | Sends about 8 req/s to `/orders` and 2 req/s to `/payments` |
| `prometheus` | 9090 | Scrapes `app:8000/metrics` every 5 seconds and answers PromQL queries |

## Metrics

| Metric | Type | Labels |
|---|---|---|
| `http_requests_total` | Counter | `endpoint`, `status` |
| `http_request_duration_seconds` | Histogram | `endpoint` |

`endpoint` only takes the values `/orders` and `/payments`, so the number of
series stays fixed.

## Failure control

```
curl -X POST localhost:8000/admin/fail                    # fail /payments for every request
curl -X POST 'localhost:8000/admin/fail?rate=0.3'         # fail 30% of /payments requests
curl -X POST 'localhost:8000/admin/fail?endpoint=/orders' # fail /orders instead
curl -X POST localhost:8000/admin/recover                 # back to healthy
curl localhost:8000/admin/status                          # current state
```

The app always starts healthy. `FAIL_ENDPOINT` and `FAIL_RATE` in
`docker-compose.yml` set the defaults that `/admin/fail` uses.

## Key query

Error ratio per endpoint over the last minute:

```
sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m]))
/
sum by (endpoint) (rate(http_requests_total[1m]))
```

## Repository layout

```
app/                 instrumented Flask service and Dockerfile
trafficgen/          background traffic generator and Dockerfile
prometheus/          prometheus.yml scrape config
killercoda/          scenario definition, step pages and verify scripts
docs/                architecture diagram and tutorial narrative
docker-compose.yml   starts app, trafficgen and prometheus together
```

## License

[MIT](LICENSE)
