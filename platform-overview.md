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

## Services live today (2026-06-05)

All services run in a homelab k3s dev cluster. Each owns its own Postgres database.

| Service | Role |
|---|---|
| `identity-people-service` | Canonical People graph, onboarding, AI settings, AccessGrant |
| `memory-service` | Memories as life-graph nodes (Journal/Trip/Milestone/Reflection/Moment) |
| `productivity-service` | Habits with confidence-over-streaks; one-tap Today |
| `finance-service` | Bank statement import, transaction ledger, categorization |
| `ledger-service` | Assets, liabilities, net worth; 15 asset types; People-graph links |
| `document-service` | Document metadata + server-side upload (PVC default, Drive optional) |
| `template-service` | Quick-capture template marketplace (curated + community) |
| `search-service` | Postgres FTS people search; consumes `person.*` events |
| `notification-service` | In-app notification feed; consumes `person.*` events |
| `onelifestack-mcp` | MCP stdio server, 12 tools — built + image pushed, not yet deployed |

**Portal** (`onelifestack-portal` v0.7.0) surfaces: Life Timeline, Today (habits), Memories,
Finances, My Legacy, People center, Template marketplace, Account.

**Test coverage:** 197 tests across the platform — unit/slice tests + full-stack E2E tests
(real Postgres via Zonky embedded-postgres, real HTTP through every controller → DB layer).
