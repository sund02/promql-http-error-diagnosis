# Diagnosing HTTP service errors with Prometheus and PromQL

## Overview

This executable tutorial teaches how to investigate an operational failure in
a running HTTP service using application metrics and PromQL. The learner
observes healthy traffic, introduces a controlled failure, diagnoses the
affected endpoint, and verifies recovery using Prometheus.

After this tutorial the learner will be able to:

1. Explain how an instrumented application exposes metrics and how Prometheus collects them.
2. Distinguish cumulative counters from request rates.
3. Write PromQL queries for request rate and error ratio grouped by endpoint.
4. Use metric labels to locate a failing endpoint and confirm recovery.
5. Explain the limitations of metrics-based diagnosis.

## System architecture

![Architecture](architecture.svg)

The traffic generator sends a steady 8 requests per second to `/orders` and 2
requests per second to `/payments`. The Python application serves those
endpoints on port 8000, records request counters and latency histograms, and
exposes them at `/metrics`. Prometheus pulls that endpoint every 5 seconds,
stores the time series, and evaluates PromQL. The learner uses the Prometheus
UI on port 9090 to query current values and graph changes over time.

## Design decisions

### Prometheus for collection and querying

Prometheus combines pull-based metric collection and PromQL querying in one
tool, which keeps the exercise focused. It is free and requires no external
service account.

### Counters for rates and ratios

Cumulative counters preserve the number of requests since process start.
PromQL can turn their increase into a request rate and divide failed request
rates by total request rates to calculate an error ratio.

### Bounded diagnostic labels

The `endpoint` and `status` labels let the learner separate failures by route
and response class. Their values come from fixed sets to avoid uncontrolled
time-series growth. Requests to `/metrics`, `/admin` paths, and unknown paths
are not counted.

### Reproducible containers and controls

The container setup pins the Python base image, the Prometheus image and the
direct Python dependencies, while scripted traffic and failure controls
reproduce the same environment and incident. One `docker compose up -d --build`
command starts it locally and in Killercoda.

### Fast feedback windows

A 5-second scrape interval and a `[1m]` query window give fast feedback so the
tutorial fits 20 to 30 minutes. Production setups often scrape every 15 to 60
seconds.

### Uneven traffic

The 8 to 2 requests-per-second split makes the aggregation blind spot visible.
A total `/payments` outage produces only about a 20% service-wide error ratio.

### Controlled failure injection

An admin API with an optional failure rate lets the learner start, vary, and
stop the incident. Partial failures represent operational incidents where
only some requests encounter the faulty path.

### One application worker

The application uses one gunicorn worker because its metrics and failure state
live in one process. Several workers would require the Prometheus Python
client's multiprocess mode.

### No Alertmanager

The goal is diagnosis with PromQL rather than alert routing, so the environment
does not include Alertmanager.

## Reflection on applicability

This approach is useful for spotting service-wide or endpoint-specific error
spikes. Aggregation can hide a complete failure on a low-volume endpoint, and
ratios can mislead when the denominator contains few requests. Scrape and
query windows delay what the learner sees. Metrics show where symptoms occur,
while logs and traces are often needed to identify the root cause. Diagnostic
labels are limited to choices made when the application is instrumented. The
approach is most relevant for developers and operators responsible for keeping
a running service healthy.

## Relevance to DevOps

The tutorial focuses on monitoring and observability. It connects application
instrumentation, automated metric collection, and operational diagnosis in
one reproducible workflow. Its scope excludes testing, continuous integration,
and deployment pipelines so the learner can focus on investigating a running
service.
