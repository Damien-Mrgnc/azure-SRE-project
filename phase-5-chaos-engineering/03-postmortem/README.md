# 03 — Post-Mortem

This folder contains the post-mortem document generated from the Phase 5 Chaos Engineering Run.

## Files

| File | Description |
|---|---|
| `postmortem-incident-001.md` | Full post-mortem in Google SRE format |

---

## What is a Post-Mortem?

A post-mortem (or "incident review") is a structured document written after an incident or chaos experiment to:

1. **Document** what happened (factual timeline)
2. **Analyze** root causes (5 Whys)
3. **Identify** what worked and what didn't
4. **Define** concrete action items to prevent recurrence

SRE culture emphasizes **blameless post-mortems**: the goal is not to find someone at fault but to understand systemic failures.

---

## Post-Mortem #001 Summary

**Incident:** Degradation during Chaos Engineering Run
**Date:** 2026-04-13
**Impact duration:** ~15 minutes (10:00 → 10:16)
**Max severity:** Sev1 (94s downtime during experiment #2)

### What Worked ✅

- Autoscaling triggered correctly (1 → 3 instances)
- 4 alerts fired with no false positives
- Azure health check restored service in 94s (SLO: < 120s)
- Full monitoring visibility (Azure Monitor + Application Insights + OTel)
- Error budget: 86.4% remaining → normal deployments allowed

### What Didn't Work ❌

- 5-minute autoscaling delay → p99 latency > 2000ms for 5 minutes
- No graceful shutdown → 8 avoidable 5xx errors
- No client-side circuit breaker

### Key Action Items

| Priority | Action |
|---|---|
| P1 | Reduce autoscaling window PT5M → PT2M |
| P1 | Configure graceful shutdown (WEBSITE_GRACEFUL_SHUTDOWN_TIMEOUT=30) |
| P2 | Reduce health check interval 30s → 15s |
| P2 | Implement circuit breaker (opossum) |

---

## Google SRE Format

The post-mortem follows the structure recommended by Google SRE:

```
1. Executive Summary
2. Detailed Timeline
3. Impact (users + SLO + error budget)
4. Root Cause Analysis (5 Whys)
5. What Worked
6. What Didn't Work
7. Action Items (short/medium/long term)
8. Key Metrics
9. Final Verdict
10. Lessons Learned
```

---

## Related Files

- Chaos run results: [`../02-chaos-results/`](../02-chaos-results/)
- Scripts used: [`../01-chaos-scripts/`](../01-chaos-scripts/)
