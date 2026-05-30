# ADR-0006: Observability — Prometheus/Grafana metrics + Sentry (SaaS) errors

- **Status:** Accepted
- **Date:** 2026-05-30
- **Deciders:** solo dev (OneLifeStack)

## Context

Services were deployed with **no runtime visibility** — no metrics, no error aggregation. Production
readiness needs both: quantitative signals (request rate/errors/latency, resource use) and
qualitative error detail (stack traces, context). The platform philosophy is **managed SaaS for
stateful concerns; self-host only what's cheap to run** (see the hosting decision).

## Decision

- **Metrics:** **Prometheus + Grafana**. Each service exposes `/actuator/prometheus` (Micrometer);
  the cluster's Prometheus scrapes it via a `ServiceMonitor`; Grafana visualizes. Self-hosted is
  cheap and stateless-enough here, and the cluster already runs the stack.
- **Errors:** **Sentry (SaaS)** via the Spring Sentry SDK, configured by a DSN per environment
  (dev/prod projects, mirroring the identity-provider split). Free tier covers dev + early prod.
- **Cross-cutting deps live in the shared backend starter** but are `optional`, so each service
  declares the metric/error deps it uses directly.

## Alternatives considered

- **Self-hosted Sentry** — open-source but heavy (multiple datastores + services); contradicts the
  "managed for stateful" stance for a solo operator. (A lighter Sentry-compatible self-host exists as
  a fallback if zero external dependency were ever required.)
- **Hosted metrics (Grafana Cloud / Datadog)** — fine for production egress, but the dev cluster
  already runs Prometheus/Grafana, so self-hosted is free and sufficient there. Production may use a
  hosted metrics backend later.

## Consequences

- Every service gets metrics by adding the registry dep + a ServiceMonitor + permitting the metrics
  endpoint; errors by setting the Sentry DSN (no DSN → the SDK no-ops, so it's safe by default).
- Distributed tracing (OpenTelemetry) is **not** done yet — a follow-up.
- Per-service Grafana dashboards are a follow-up (the metrics exist; dashboards make them glanceable).
- The metrics endpoint is cluster-internal (not exposed at the edge) and carries no user data.
