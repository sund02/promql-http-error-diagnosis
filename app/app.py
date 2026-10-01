"""Instrumented HTTP service for the PromQL error-diagnosis tutorial.

Serves /orders and /payments, exposes Prometheus metrics on /metrics, and
supports failure injection through /admin/fail and /admin/recover.

Metric labels are restricted to the fixed ENDPOINTS and status codes so series
cardinality stays bounded. The service always starts healthy; FAIL_ENDPOINT and
FAIL_RATE only set the defaults used by POST /admin/fail.
"""

import os
import random
import threading
import time

from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

ENDPOINTS = ("/orders", "/payments")

REQUESTS = Counter(
    "http_requests_total",
    "HTTP requests handled, by endpoint and status code.",
    ["endpoint", "status"],
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds, by endpoint.",
    ["endpoint"],
)

for _endpoint in ENDPOINTS:
    REQUESTS.labels(_endpoint, "200")
    LATENCY.labels(_endpoint)

app = Flask(__name__)


def parse_rate(value):
    """Return value as a failure rate in (0, 1].

    Raises:
        ValueError: if value is not a number or is outside (0, 1].
    """
    rate = float(value)
    if not 0 < rate <= 1:
        raise ValueError("rate must be in (0, 1]")
    return rate


DEFAULT_ENDPOINT = os.environ.get("FAIL_ENDPOINT", "/payments")
DEFAULT_RATE = parse_rate(os.environ.get("FAIL_RATE", "1.0"))
if DEFAULT_ENDPOINT not in ENDPOINTS:
    raise ValueError(f"FAIL_ENDPOINT must be one of {list(ENDPOINTS)}")

_lock = threading.Lock()
_failure = None


def get_failure():
    with _lock:
        return _failure


def set_failure(failure):
    global _failure
    with _lock:
        _failure = failure


def status_body():
    failure = get_failure()
    if failure is None:
        return {"failing": None, "rate": None}
    return {"failing": failure[0], "rate": failure[1]}


def handle(endpoint, body):
    """Serve a request to endpoint and record its metrics.

    While endpoint is the failure target, each request fails with HTTP 500 with
    probability equal to the configured rate; otherwise body is returned with 200.
    Increments http_requests_total and observes http_request_duration_seconds.
    """
    start = time.perf_counter()
    time.sleep(random.uniform(0.005, 0.05))

    failure = get_failure()
    if failure and failure[0] == endpoint and random.random() < failure[1]:
        status, payload = 500, {"error": "injected failure"}
    else:
        status, payload = 200, body

    LATENCY.labels(endpoint).observe(time.perf_counter() - start)
    REQUESTS.labels(endpoint, str(status)).inc()
    return jsonify(payload), status


@app.get("/orders")
def orders():
    return handle("/orders", {"orders": [{"id": random.randint(1000, 9999), "items": random.randint(1, 5)}]})


@app.get("/payments")
def payments():
    return handle("/payments", {"payment": {"id": random.randint(1000, 9999), "status": "captured"}})


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.post("/admin/fail")
def admin_fail():
    endpoint = request.args.get("endpoint", DEFAULT_ENDPOINT)
    if endpoint not in ENDPOINTS:
        return jsonify({"error": f"endpoint must be one of {list(ENDPOINTS)}"}), 400
    try:
        rate = parse_rate(request.args.get("rate", DEFAULT_RATE))
    except ValueError:
        return jsonify({"error": "rate must be a number in (0, 1]"}), 400
    set_failure((endpoint, rate))
    return jsonify(status_body())


@app.post("/admin/recover")
def admin_recover():
    set_failure(None)
    return jsonify(status_body())


@app.get("/admin/status")
def admin_status():
    return jsonify(status_body())


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
