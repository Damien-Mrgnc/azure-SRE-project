# Phase 5 — Chaos Engineering

## Objective

Validate system resilience through controlled experiments that inject real failures, and verify that SRE mechanisms from previous phases (autoscaling, alerts, health check) respond correctly.

**Chaos Engineering Principle:** "Break things on purpose to build more resilient systems."

---

## Structure

```
phase-5-chaos-engineering/
├── 01-chaos-scripts/           # Chaos injection scripts
│   ├── chaos-cpu-stress.sh         # CPU stress via concurrent requests
│   ├── chaos-kill-instance.sh      # Kill instance via az webapp restart
│   ├── chaos-latency-inject.js     # Latency injection proxy
│   ├── azure-chaos-experiment.json # Azure Chaos Studio experiment definition
│   ├── README_FR.md
│   └── README.md
│
├── 02-chaos-results/           # Chaos run results and metrics
│   ├── chaos-run-report.json       # Full report (2 experiments)
│   ├── metrics-during-chaos.json   # Minute-by-minute metrics timeline
│   ├── README_FR.md
│   └── README.md
│
└── 03-postmortem/              # Google SRE format post-mortem
    ├── postmortem-incident-001.md  # Full post-mortem document
    ├── README_FR.md
    └── README.md
```

---

## Experiments Executed

### Experiment #1 — CPU Stress

| Parameter | Value |
|---|---|
| Script | `chaos-cpu-stress.sh` |
| Duration | 10 minutes |
| Concurrency | 20 workers |
| CPU peak reached | 87% |
| Scale-outs triggered | 2 (1→2→3 instances) |
| Alerts fired | `slo-latency-breach` (Sev2), `alert-asp-cpu-high` (Sev2) |
| Verdict | PARTIAL — latency SLO breached (expected), autoscaling correct |

### Experiment #2 — Kill Instance

| Parameter | Value |
|---|---|
| Script | `chaos-kill-instance.sh` |
| Method | `az webapp restart` |
| Downtime | **94 seconds** |
| Recovery SLO | < 120s ✅ |
| Alerts fired | `alert-webapp-5xx` (Sev2), `slo-availability-breach` (Sev1) |
| Verdict | PASS — service restored in < 2 minutes |

---

## Key Results

```
┌────────────────────────────────────────────────────────────────┐
│              CHAOS ENGINEERING — GLOBAL SUMMARY                │
├─────────────────────────────┬──────────────────────────────────┤
│ Autoscaling triggered       │ ✅ Yes (×2)                      │
│ Alerts correctly fired      │ ✅ 4/4                           │
│ Self-healing confirmed      │ ✅ Yes (94s)                     │
│ SLO breach during chaos     │ ⚠️  Yes (expected)               │
│ SLO breach after chaos      │ ✅ No                            │
│ Error budget consumed       │ 13.6% (86.4% remaining)          │
│ Deployment policy           │ 🟢 GREEN                         │
└─────────────────────────────┴──────────────────────────────────┘
```

---

## Integration with Previous Phases

| Phase | Mechanism | Validated in Phase 5 |
|---|---|---|
| Phase 1 — Monitoring | Azure Monitor metrics | ✅ CPU%, latency, 5xx captured |
| Phase 2 — Logs/Tracing | OTel traces, JSON logs | ✅ Traces visible during downtime |
| Phase 3 — Autoscaling | Scale-out CPU > 75% | ✅ Triggered correctly |
| Phase 4 — SLO/Alerts | KQL alerts, error budget | ✅ 4 alerts fired, budget tracked |

---

## Hypotheses Validated

| # | Hypothesis | Result |
|---|---|---|
| 1 | Autoscaling absorbs CPU load before availability SLO breach | ✅ VALIDATED |
| 2 | Health check restores service in < 2 min after restart | ✅ VALIDATED (94s) |
| 3 | SLO alerts fire correctly | ✅ VALIDATED (4/4) |

---

## Post-Chaos Action Items

| Priority | Action | Sprint |
|---|---|---|
| P1 | Reduce autoscaling window PT5M → PT2M | Sprint N |
| P1 | Configure graceful shutdown (30s) | Sprint N |
| P2 | Health check interval 30s → 15s | Sprint N+1 |
| P2 | Client-side circuit breaker (opossum) | Sprint N+1 |
| P3 | Multi-zone deployment | Backlog |

See full post-mortem: [`03-postmortem/postmortem-incident-001.md`](03-postmortem/postmortem-incident-001.md)

---

## Resources

- [Azure Chaos Studio Documentation](https://learn.microsoft.com/en-us/azure/chaos-studio/)
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Google SRE Book — Chapter 15: Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- [Netflix Chaos Monkey](https://github.com/Netflix/chaosmonkey)
