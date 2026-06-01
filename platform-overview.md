# Platform Overview

**OneLifeStack is a connected life platform** — a personal operating system that helps people
preserve, understand, and grow what matters most: relationships, memories, identity, experiences,
and life story.

> *Your story. Connected.*

Most software organizes data. OneLifeStack organizes life. Traditional apps create silos — a
finance app that knows nothing about your people, a journal with no memory of shared moments.
OneLifeStack connects them through a canonical life graph (people, events, places, memories) that
every app reads from and writes to. Apps are different lenses into a single life, not independent
products.

The platform is the hero. Individual apps are supporting characters. The long-term vision includes
AI agents that act as life companions — contextual, caring, memory-aware — operating over the life
graph.

Reached through web, native mobile (Expo), wearables, and agents (MCP), unified by one identity
and a canonical People graph.

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

The **event backbone** is live: the People service emits `person.*` events through a transactional
outbox to the event broker, and **two independent consumers** react — a **Search** service
(owner-scoped full-text index) and a **Notification** service (owner-scoped in-app notifications).
One event fans out to both, closing the full round-trip: produce → broker → consume → project → query.

**Observability** is wired across all services: Prometheus metrics (RED + JVM) in Grafana, error
tracking via Sentry.

**The public marketing site (`onelifestack.com`) is live** — redesigned to reflect the connected
life platform vision, with an animated interactive life graph as the hero visual and an emotional
narrative arc ("Your story. Connected."). Waitlist is open.

Build progresses domain by domain from here — SpendStack migration is next.
