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

## Status

The foundation is in place and the first vertical slice is live in a development cluster, proven
end-to-end from a browser: sign-in → identity token → portal → People service → database → back.

The **event backbone** is also live: the People service emits `person.*` events through a
transactional outbox to the event broker, and a dedicated **Search service** consumes them into an
owner-scoped full-text index — so a person becomes searchable in the portal moments after they're
created. That closes the full event round-trip (produce → broker → consume → project → query).
Build progresses domain by domain from there.
