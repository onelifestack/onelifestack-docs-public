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

## Life lenses

The platform is organised into **7 human-centred lenses** — each answers a question about life,
not a software category. They appear in the Dock (portal + /preview) in this canonical order:

| Lens | Question | Backend | Status |
|---|---|---|---|
| **Memories** | What do I want to remember? | `memory` (monolith) | V3 live — tags, On This Day, experiences, person-filter |
| **People** | Who matters to me? | `identity` (monolith) | V1 live |
| **Self** | How am I doing and becoming? | `productivity` (monolith) | V3 live (Today, habits, goals, vision, mood sparkline) |
| **Responsibilities** | What needs care? | `finance` + `ledger` + `lifegraph` (monolith) | V1 live (finances, life objects, recurring, budgets) |
| **Work & Purpose** | What am I building and growing through? | `productivity` (monolith) | Goals + Vision tabs live |
| **Passions** | What brings me joy? | `knowledge` (monolith) | V2 live (books, ideas, learnings; read status) |
| **Legacy** | What should remain? | `document` + `archives` + `lifegraph` (monolith) | V1 live (documents, artefacts, records, life events) |

Quick capture is the entry point for every lens — one question, saves immediately, optional expand.

## Platform today (2026-06-29)

All 12 domain packages run in a **single modular monolith** (`onelifestack-platform` v0.1.7), one Spring Boot 3.4.4 process, one `platform` Postgres DB with 12 schemas managed by per-schema Flyway.

| Domain package | Role |
|---|---|
| `identity` | Canonical People graph, onboarding, AI settings, AccessGrant, preview import |
| `memory` | Memories as life-graph nodes (Journal/Trip/Milestone/Reflection/Moment) |
| `productivity` | Habits with confidence-over-streaks; one-tap Today; weekly grid; goals; vision |
| `finance` | Bank statement import, transaction ledger, categorization, budgets, recurring |
| `ledger` | Assets, liabilities, net worth; 15 asset types; People-graph links |
| `document` | Document metadata + server-side upload (PVC default, Drive optional) |
| `template` | Quick-capture template marketplace (curated + community) |
| `search` | Postgres FTS search (persons + memories); consumes domain events |
| `notification` | In-app notification feed; consumes domain events |
| `knowledge` | Books, ideas, learnings; read status + progress |
| `archives` | Artefacts, records |
| `lifegraph` | LifeObjects, Places, Responsibilities, LifeEvents, Vendors — cross-domain connective layer |

**Portal** (`onelifestack-portal` v1.48.0): 7-lens Dock-based tab host. Guest-first with per-lens conversion prompts. **Manrope** font throughout (matches `life` preset). All API URLs → `platform.onelifestack.homelab.local`.

**Marketing site** (`onelifestack.com` v1.37.0): dark `life-nocturne` design; local-first `/preview` mode with 7-lens Dock (canonical order + icons matching portal); `LIFE_SPACES` driven by 7-lens model with human questions; import handoff to portal on sign-in.

**MCP** (`onelifestack-mcp` v0.2.1): 16 tools, `olsat_` agent tokens, provider-neutral (Anthropic + OpenAI). Live at `mcp.onelifestack.homelab.local`.

**Security posture:** Rate limiting via Bucket4j (per-UID authenticated, per-IP unauthenticated). `CorrelationIdFilter` + `RequestAuditFilter` in commons. BYOK keys protected via `/internal/v1/`. Document-service has MIME allowlist + 25MB cap.

**Test coverage:** 197+ tests across the platform — unit/slice tests + full-stack E2E tests.
