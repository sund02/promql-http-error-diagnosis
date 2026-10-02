# Reflect on what metrics can and cannot tell you

## 1. Aggregation blind spots

Why did the overall ratio read about 20% during a total `/payments` failure,
and about 6% at failure rate 0.3, while the endpoint ratio was 100% or 30%?
What would happen if `/payments` carried only 1% of traffic?

<details>
<summary>Show answer</summary>

The overall ratio is a traffic-weighted average. `/payments` carries 20% of
the traffic, so a total failure contributes about 20% overall and a 30%
failure contributes about 6%. At 1% of traffic, a total outage would appear
as only 1% overall and could remain below an alert threshold. Aggregate the
data to detect a service problem, then group by a label to localize it.

</details>

## 2. Ratios under low traffic

An endpoint receives 2 requests in one minute and 1 fails, so its error ratio
is 50%. Why can that number be misleading, and what else should you check?

<details>
<summary>Show answer</summary>

The denominator is too small to show a stable pattern. Require a minimum
request rate before acting on the ratio, use a longer window, and inspect the
absolute error count as well.

</details>

## 3. Observation delay

Which delays sit between a failure starting and the query showing it? What do
shorter query windows trade away?

<details>
<summary>Show answer</summary>

Prometheus may wait up to the 5-second scrape interval to collect the first
change. The 1-minute `rate()` window then averages new data with earlier
samples, and an alert can add its configured `for` duration. A shorter window
reacts faster but produces a noisier value.

</details>

## 4. Design choices

Why does the app use only `endpoint` and `status` labels? Why use Prometheus,
containers, and scripted traffic and failure controls?

<details>
<summary>Show answer</summary>

The label values come from bounded sets. User IDs or raw URLs would create a
series for each value and make the time-series count grow. Prometheus keeps
collection and querying in one tool. Containers and scripts reproduce the
same environment, traffic, and incident for each learner.

</details>

## 5. Metrics, logs, and traces

What could the metrics not tell you about this failure, and what would logs
or traces add?

<details>
<summary>Show answer</summary>

The metrics cannot identify which requests failed, the error message, why the
failure happened, or which downstream call failed. Metrics locate symptoms.
Logs provide per-request detail, while traces show the path across services,
where the root cause is usually found.

</details>

## Design decisions and the DevOps practices behind them

- **Containers and a Compose file (infrastructure as code, reproducibility):**
  the environment lives in versioned files that pin the Python base image,
  the Prometheus image and the direct Python dependencies, so it starts the
  same way in Killercoda and on a laptop.
- **Instrumentation inside the app (observability):** the service reports its
  own request counts and latency, so a failure that leaves the process running
  is still visible.
- **Automated scraping and scripted checks (automation):** Prometheus collects
  metrics every 5 seconds without manual steps, and each step is verified by a
  script.
- **Bounded labels (sustainable monitoring):** only `endpoint` and `status`,
  so the number of series and the cost of queries stay predictable as traffic
  grows.
- **Prometheus:** collection and querying in one free, open-source tool.
  Because it pulls metrics, it also records through `up` when a target stops
  answering. It is a CNCF graduated project and the usual metrics system in
  Kubernetes setups. A hosted service such as Datadog would need an account
  and an API key, which this tutorial avoids. A log stack such as ELK is built
  for searching individual events, not for computing rates and ratios over
  time.
- **Scripted failure injection:** the incident can be rehearsed safely and
  repeated exactly, so diagnosis can be practiced before it is needed in
  production.

## When this approach does not fit

- **Finding the root cause:** the metrics show which endpoint fails, not why.
  Logs and traces answer that.
- **Very low traffic or batch jobs:** with few requests the ratio jumps between
  0 and 100%. Absolute error counts or the time of the last success are more
  reliable signals.
- **Questions about one request or one user:** that detail belongs in logs or
  traces. Adding user IDs as labels would multiply the number of series.
- **Failures along a dimension you did not label:** if errors depend on
  something like region or customer, grouping by `endpoint` cannot localize
  them.
- **Very short incidents:** a failure shorter than the scrape interval and
  query window can be averaged away.

## Where this approach is useful

This approach helps spot service-wide and endpoint-specific error spikes and
works well as the first look during an incident. It is most relevant for
developers and operators responsible for keeping a running service healthy.
