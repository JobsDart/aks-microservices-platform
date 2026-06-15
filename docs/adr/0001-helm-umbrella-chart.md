# ADR-0001: Single umbrella Helm chart with a services list

- **Status:** Accepted
- **Date:** 2026-06-14

## Context
The platform has four services that are operationally near-identical (same image pattern, probes,
labels, metrics, resource shape). Options: a chart per service, a shared library chart, or one
umbrella chart that loops over a `services` list.

## Decision
Use **one umbrella chart** (`charts/platform`) that ranges over a `services:` list in `values.yaml`,
rendering a Deployment + Service (+ optional HPA/ServiceMonitor) per entry.

## Rationale
- Guarantees consistency: every service gets the same probes, labels, metrics and limits by
  construction.
- Adding/removing a service is a one-line values change — ideal for a cohesive platform delivered as a
  unit via a single ArgoCD Application.

## Consequences
- ✅ Minimal duplication; consistent operational surface; trivial to extend.
- ⚠️ Services release together, not independently. For this platform that is desirable; if a service
  later needs an independent lifecycle, it can be split into its own chart without changing the others.
