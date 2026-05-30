# ADR-0002: Firebase credentials — ADC for local dev, mounted key in the cluster

- **Status:** Accepted
- **Date:** 2026-05-30
- **Deciders:** solo dev (OneLifeStack)

## Context

Backends verify Firebase ID tokens via the Admin SDK, which needs Google credentials. The shared
backend starter supports both a service-account **key file** and **Application Default Credentials
(ADC)**. Two constraints shaped the choice: the GCP org enforces a policy that **blocks
service-account key creation** by default, and a cluster pod cannot use a developer's laptop-local
ADC.

## Decision

- **Local dev:** use **ADC** (`gcloud auth application-default login`) — no key file to manage.
- **In-cluster:** mount a **service-account key** as a file via a sealed secret, with the starter
  pointed at that path.
- To mint the one key needed: temporarily relax the org policy, generate the key, seal it, **delete
  the raw key**, then **re-enforce** the policy. The only key that exists lives encrypted in the
  cluster.

## Alternatives considered

- **Downloaded key for local too** — rejected; ADC avoids a key on disk and aligns with the policy.
- **Leave the org policy relaxed** — rejected; re-enforcing keeps the secure default.
- **Workload Identity in the pod** — the cleaner long-term answer, but not automatic on a bare
  cluster; revisit for production.

## Consequences

- No long-lived key on any developer machine; the single key is an encrypted in-cluster secret.
- Minting another key requires deliberately relaxing then re-enforcing the policy.
- Note: the gcloud CLI account (for admin/policy commands) is a separate credential layer from ADC
  (for SDKs); both can be needed.
- For production, plan Workload Identity to avoid any long-lived key.
