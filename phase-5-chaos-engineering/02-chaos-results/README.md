# 02 — Chaos Run Results

This folder contains the detailed results from the Chaos Engineering experiments executed on 2026-04-13.

## Files

| File | Description |
|---|---|
| `chaos-run-report.json` | Full run report — 2 experiments, alerts, SLO evaluations, autoscaling events |
| `metrics-during-chaos.json` | Minute-by-minute timeline — CPU%, HTTP requests, latency percentiles, memory |

---

## Run Summary

**Date:** 2026-04-13
**Total Duration:** 25 minutes
**Experiments Run:** 2
**Overall Verdict:** PASS — system is resilient, alerts fired correctly, automatic recovery confirmed

---

## Experiment #1 — CPU Stress (10:00 → 10:10)

**Key results:**

| Metric | Value |
|---|---|
| CPU Peak | 87% |
| CPU avg during chaos | 79% |
| Peak instances | 3 (scale-out ×2) |
| Requests sent | 1840 |
| HTTP errors | 13 (error rate 0.71%) |
| Latency p95 during chaos | 2241ms |
| Latency p99 peak | 2318ms |

**Alerts fired:**

| Alert | Fired | Severity | Resolved |
|---|---|---|---|
| `slo-latency-breach` | 10:03:42 | Sev2 | 10:10:12 |
| `alert-asp-cpu-high` | 10:05:18 | Sev2 | 10:11:45 |

**Autoscaling events:**

| Time | Event | Trigger |
|---|---|---|
| 10:05:12 | Scale-out 1 → 2 | CPU 76% > 75% |
| 10:06:30 | Scale-out 2 → 3 | CPU 81% > 75% |
| 10:14:55 | Scale-in 3 → 2 | CPU 19% < 25% |
| 10:25:10 | Scale-in 2 → 1 | CPU 12% < 25% |

**SLO evaluation:**

| SLO | Target | Actual | Verdict |
|---|---|---|---|
| Availability | 99.9% | 99.29% | BREACH (expected during chaos) |
| Latency p95 | 500ms | 2241ms | BREACH (expected during chaos) |
| Error rate | < 1% | 0.71% | PASS ✅ |

---

## Experiment #2 — Kill Instance (10:13 → 10:16)

**Key results:**

| Metric | Value |
|---|---|
| Method | `az webapp restart` |
| First 503 error | T+8s (10:13:08) |
| Downtime duration | **94 seconds** |
| Recovery SLO | < 120s target ✅ |
| 5xx errors | 8 |
| Error rate (5min window) | 2.7% |

**HTTP probe timeline:**

| Time | Status |
|---|---|
| 10:13:05 | 200 (pre-chaos) |
| 10:13:10 | 503 ← downtime start |
| 10:13:45 | 502 (transition) |
| 10:13:55 | 200 ← partial recovery |
| 10:14:42 | 200 ← fully restored |

**Alerts fired:**

| Alert | Fired | Severity | Resolved |
|---|---|---|---|
| `alert-webapp-5xx` | 10:13:25 | Sev2 | 10:15:10 |
| `slo-availability-breach` | 10:13:30 | Sev1 | 10:15:10 |

---

## Global Error Budget Impact

| Metric | Value |
|---|---|
| Monthly budget | 43.2 minutes |
| Consumed today | 5.87 minutes (13.6%) |
| Budget remaining | 37.33 minutes (**86.4%**) |
| Policy status | 🟢 GREEN — normal deployments allowed |

---

## Related Files

- Scripts used: [`../01-chaos-scripts/`](../01-chaos-scripts/)
- Post-mortem: [`../03-postmortem/postmortem-incident-001.md`](../03-postmortem/postmortem-incident-001.md)
