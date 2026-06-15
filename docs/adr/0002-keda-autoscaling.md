# ADR-0002: KEDA (queue-depth) autoscaling for the Notification service

- **Status:** Accepted
- **Date:** 2026-06-14

## Context
The Notification service is an event-driven worker consuming contract events from Azure Service Bus.
CPU-based HPA is a poor demand signal for such workers — a backlog can build with low CPU, and pods
can't scale to zero when idle.

## Decision
Scale Notification with **KEDA** on **Service Bus queue depth** (`messageCount` per replica), keeping a
CPU HPA only as a safety net for the request-serving services.

## Rationale
- Queue depth is the true demand signal for a worker — it scales out under backlog and down (toward
  `minReplicaCount`) when idle, which CPU HPA cannot do well.
- It maps directly to the CoMa Outbox + Service Bus messaging design, so the autoscaling reflects the
  real architecture rather than a generic metric.

## Consequences
- ✅ Responsive, cost-efficient scaling driven by actual workload.
- ✅ Demonstrates event-driven autoscaling — a differentiator few portfolios show.
- ⚠️ Adds KEDA + a TriggerAuthentication/secret to the platform; documented in DEPLOYMENT.md.
