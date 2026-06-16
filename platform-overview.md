# Platform Overview

OneLifeStack is a **multi-client life-management platform** reached through web, native mobile
(Expo), wearables, and agents (MCP), unified by one identity and a canonical People graph.

## Principles

- **One identity everywhere.** Firebase is the single identity provider; the Firebase UID is the
  universal identity key across every client and service. ([ADR-0001](adr/0001-firebase-single-idp.md))
- **Canonical People graph.** One `Person` = any human (a principal with an identity, or a referent
  with none). Apps keep their own person rows but call the People service to resolve a `person_id`.
  Merges are **user-confirmed and reversible — never silent.**
- **Google-style access.** Signing in grants the apps by default; entitlements are a control lever
  (ban, beta-gate, feature flags), not an access gate.
- **Database per service, no cross-DB joins.** Each service owns its database; services integrate
  only via events and typed APIs. ([ADR-0003](adr/0003-db-per-service-no-cross-db-joins.md))
- **Event backbone.** Kafka + a transactional outbox per service; dedicated Search and Notification
  services consume events.
- **Shared foundation.** A platform-agnostic TypeScript core (auth contract, API client, typed
  service clients, design tokens), with thin per-platform UI kits (web + React Native) on top.
- **Strangler decomposition.** Carve large legacy apps into domain services over time, via events.

## Shape

- **Clients** — web portal, marketing site, native mobile, wearables, MCP agents.
- **Identity & People service** — the canonical graph: resolve, suggest, merge/unmerge.
- **Apps** — Spends, LifeLog, and more, each its own service + database.
- **Platform services** — Search and Notifications (event consumers), an agent/MCP layer.
- **Shared code** — `@onelifestack/core` → `@onelifestack/ui` (web) + `@onelifestack/ui-native` (RN);
  a Spring Boot starter for backend cross-cutting concerns (auth, error envelope, CORS, audit).

See the [architecture diagrams](architecture.md) for the C4 context and container views.

## Life domains

The platform is organised into 7 life domains — each a distinct space in the portal:

| Domain | Backend | Status |
|---|---|---|
| Memories | `memory-service` | V1 live |
| People & Care | `identity-people-service` | V1 live |
| Wealth | `finance-service` + `ledger-service` | V1 live |
| Growth | `productivity-service` | V2 live (weekly view, confidence explainer) |
| Legacy | `identity-people-service` + `ledger-service` | V1 live |
| Knowledge | — (not yet built) | V1 design proposed |
| Archives | `document-service` + `identity-people-service` | V1 design proposed |

Quick capture is the entry point for every domain — one question, saves immediately, optional expand.

## Services live today (2026-06-16)

All services run in a homelab k3s dev cluster. Each owns its own Postgres database.

| Service | Role |
|---|---|
| `identity-people-service` | Canonical People graph, onboarding, AI settings, AccessGrant, preview import |
| `memory-service` | Memories as life-graph nodes (Journal/Trip/Milestone/Reflection/Moment) |
| `productivity-service` | Habits with confidence-over-streaks; one-tap Today; weekly grid |
| `finance-service` | Bank statement import, transaction ledger, categorization, budgets, recurring |
| `ledger-service` | Assets, liabilities, net worth; 15 asset types; People-graph links |
| `document-service` | Document metadata + server-side upload (PVC default, Drive optional) |
| `template-service` | Quick-capture template marketplace (curated + community) |
| `search-service` | Postgres FTS people search; consumes `person.*` events |
| `notification-service` | In-app notification feed; consumes `person.*` + `access.grant.*` events |
| `onelifestack-mcp` | MCP HTTP multi-user server, 16 tools, `olsat_` agent tokens |

**Portal** (`onelifestack-portal` v1.21.0) surfaces 7 Life Spaces via a Dock-based tab host. Guest-first with per-space conversion prompts for Tier-2 spaces (Wealth, People, Legacy).

**Marketing site** (`onelifestack.com` v1.33.0): dark connected-life design; local-first `/preview` mode (IndexedDB, no account required); import handoff to portal on sign-in.

**Security posture (2026-06-16):** Rate limiting via Bucket4j active on **all 8 backend services** (per-UID authenticated, per-IP unauthenticated). `CorrelationIdFilter` + `RequestAuditFilter` in commons give every service correlation IDs + structured audit logs. BYOK keys protected via `/internal/v1/` + shared secret. Document-service has MIME allowlist + 25MB cap.

**Test coverage:** 197+ tests across the platform — unit/slice tests + full-stack E2E tests
(real Postgres via Zonky embedded-postgres, real HTTP through every controller → DB layer).
