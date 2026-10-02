# Done

You diagnosed an HTTP 500 incident using only metrics and PromQL. Along the
way you:

- confirmed Prometheus was scraping the app before trusting any query
- recorded a baseline of request rates per endpoint
- injected a failure and saw a new `status="500"` series appear while the
  target stayed `up`
- watched the overall error ratio understate a total outage of `/payments`,
  then found it by grouping `by (endpoint)`
- recovered and watched the ratio return to 0 as the query window moved on

## Queries to keep

Request rate per endpoint:

```
sum by (endpoint) (rate(http_requests_total[1m]))
```

Error ratio per endpoint:

```
sum by (endpoint) (rate(http_requests_total{status=~"5.."}[1m]))
/
sum by (endpoint) (rate(http_requests_total[1m]))
```

## Where to go next

The natural next step is turning the per-endpoint error ratio into a
Prometheus alerting rule, with Alertmanager routing the notification. This
tutorial leaves alerting out so the focus stays on reading the metrics.

- [PromQL basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Query functions, including `rate()` and `histogram_quantile()`](https://prometheus.io/docs/prometheus/latest/querying/functions/)
- [Histograms and summaries](https://prometheus.io/docs/practices/histograms/)
- [Alerting rules](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Source code for this tutorial](https://github.com/sund02/promql-http-error-diagnosis)
