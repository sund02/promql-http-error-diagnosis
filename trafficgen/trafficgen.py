"""Send steady traffic to the tutorial app and report interval counts."""

import math
import os
import signal
import threading
import time

import requests

REPORT_INTERVAL_SECONDS = 10
REQUEST_TIMEOUT_SECONDS = 2

stop_event = threading.Event()
counts_lock = threading.Lock()
interval_counts = {
    "/orders": {"ok": 0, "err": 0},
    "/payments": {"ok": 0, "err": 0},
}


def positive_rate(name, default):
    """Read a finite, positive request rate from the environment."""
    raw_value = os.environ.get(name, default)
    try:
        rate = float(raw_value)
    except ValueError as error:
        raise SystemExit(f"{name} must be a positive number, got {raw_value!r}") from error
    if not math.isfinite(rate) or rate <= 0:
        raise SystemExit(f"{name} must be a positive number, got {raw_value!r}")
    return rate


def record(endpoint, outcome):
    with counts_lock:
        interval_counts[endpoint][outcome] += 1


def send_requests(app_url, endpoint, rate):
    """Send requests on a monotonic schedule until shutdown is requested."""
    session = requests.Session()
    interval = 1 / rate
    next_request = time.monotonic()

    while not stop_event.is_set():
        delay = next_request - time.monotonic()
        if delay > 0 and stop_event.wait(delay):
            break

        try:
            response = session.get(
                f"{app_url}{endpoint}", timeout=REQUEST_TIMEOUT_SECONDS
            )
            outcome = "ok" if 200 <= response.status_code < 400 else "err"
        except requests.RequestException:
            outcome = "err"

        record(endpoint, outcome)
        next_request += interval


def print_reports():
    """Print and reset counts for each completed reporting interval."""
    next_report = time.monotonic() + REPORT_INTERVAL_SECONDS
    while not stop_event.is_set():
        if stop_event.wait(max(0, next_report - time.monotonic())):
            break

        with counts_lock:
            orders = interval_counts["/orders"].copy()
            payments = interval_counts["/payments"].copy()
            interval_counts["/orders"] = {"ok": 0, "err": 0}
            interval_counts["/payments"] = {"ok": 0, "err": 0}

        print(
            f"orders ok={orders['ok']} err={orders['err']} | "
            f"payments ok={payments['ok']} err={payments['err']}",
            flush=True,
        )
        next_report += REPORT_INTERVAL_SECONDS


def request_shutdown(_signum, _frame):
    stop_event.set()


def main():
    app_url = os.environ.get("APP_URL", "http://app:8000").rstrip("/")
    rates = {
        "/orders": positive_rate("ORDERS_RPS", "8"),
        "/payments": positive_rate("PAYMENTS_RPS", "2"),
    }

    signal.signal(signal.SIGTERM, request_shutdown)
    signal.signal(signal.SIGINT, request_shutdown)

    for endpoint, rate in rates.items():
        worker = threading.Thread(
            target=send_requests,
            args=(app_url, endpoint, rate),
            daemon=True,
            name=endpoint.removeprefix("/"),
        )
        worker.start()

    print_reports()


if __name__ == "__main__":
    main()
