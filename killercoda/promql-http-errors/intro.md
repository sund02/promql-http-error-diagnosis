# Diagnosing HTTP service errors with Prometheus and PromQL

In this tutorial you observe healthy traffic, introduce a controlled failure,
diagnose the affected endpoint with PromQL, and verify recovery. It takes about
20 to 30 minutes and requires only a free Killercoda account, with nothing to
install.

## The problem

A running service can pass every health check while one of its endpoints fails
for every customer. The process is up, the metrics endpoint answers, and a
dashboard that shows one service-wide error number looks only mildly worse.
Whoever is on call has to find the affected endpoint and confirm the fix,
using data the service already exposes. This tutorial works through that
situation with Prometheus and PromQL.

## Intended learning outcomes

After this tutorial you will be able to:

1. Explain how an instrumented application exposes metrics and how Prometheus collects them.
2. Distinguish cumulative counters from request rates.
3. Write PromQL queries for request rate and error ratio grouped by endpoint.
4. Use metric labels to locate a failing endpoint and confirm recovery.
5. Explain the limitations of metrics-based diagnosis.

## How the environment works

![Architecture](./assets/architecture.svg)

A traffic generator sends requests to two endpoints on an instrumented HTTP
application. The application exposes request counters on `/metrics`, labeled
by endpoint and status code, and Prometheus collects those metrics every 5
seconds for querying and graphing.

## How this relates to DevOps

DevOps treats running a service as part of the same loop as building it, and
the monitoring stage of that loop depends on observability. In this tutorial
the app is instrumented in its own code, Prometheus collects its metrics
automatically, and the whole environment is defined in a versioned Docker
Compose file, so it starts the same way for every learner. The architecture
and the reasons behind each design choice are described in full in
[docs/tutorial.md](https://github.com/sund02/promql-http-error-diagnosis/blob/main/docs/tutorial.md).

## How to use this scenario

Setup starts automatically. Wait for `Environment ready.` in the terminal,
then click a command to run it and press **Check** to verify each step.
