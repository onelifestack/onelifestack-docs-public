# OneLifeStack — Architecture (C4 diagrams)

Diagrams-as-code (Mermaid, renders natively on GitHub). Following the **C4 model**: System Context →
Containers. Each diagram marks what's **live today** vs. **target/planned**. The narrative source of
truth is `PLATFORM-PLAN.md`; current build status is `FOUNDATION-STATUS.md`; key decisions are in
[`adr/`](adr/README.md).

---

## Level 1 — System Context

Who uses OneLifeStack and the external systems it depends on.

```mermaid
C4Context
  title System Context — OneLifeStack

  Person(user, "User", "A human using OneLifeStack across web, mobile, wearables")
  Person(agent, "Agent", "MCP / automation acting on a user's behalf")

  System_Boundary(ols, "OneLifeStack Platform") {
    System(platform, "OneLifeStack", "Multi-client life-management platform: identity/people, apps (Spends, LifeLog, …), search, notifications")
  }

  System_Ext(firebase, "Firebase Auth", "Single IdP — issues/verifies identity tokens (ADR-0001)")
  System_Ext(google, "Google Sign-In", "OAuth provider behind Firebase")

  Rel(user, platform, "Uses", "HTTPS / native")
  Rel(agent, platform, "Acts via", "MCP / API + scoped token")
  Rel(user, google, "Signs in with")
  Rel(platform, firebase, "Verifies ID tokens with")
  Rel(google, firebase, "Federates to")
```

---

## Level 2 — Containers (current live slice)

What's **actually deployed** in a k3s dev cluster today. The first vertical slice plus the **event
backbone** and the **first event consumer** (search) — the full event round-trip is live.

```mermaid
C4Container
  title Containers — Live slice (a k3s dev cluster)

  Person(user, "User", "Browser")

  System_Ext(firebase, "Firebase Auth", "single IdP")

  System_Boundary(ols, "OneLifeStack") {
    Container(portal, "onelifestack-portal", "React + Vite SPA on nginx", "Launcher + People center (search) + Account. Built on @onelifestack/ui + /core")
    Container(people, "identity-people-service", "Spring Boot 3.4 / Java 21", "Canonical People graph: resolve, suggestions, reversible merge/unmerge. Emits person.* via a transactional outbox")
    Container(search, "search-service", "Spring Boot 3.4 / Java 21", "Consumes person.* → owner-scoped full-text index; search API")
    Container(notify, "notification-service", "Spring Boot 3.4 / Java 21", "Consumes person.* → owner-scoped in-app notifications; feed API")
    ContainerQueue(kafka, "Kafka (KRaft)", "event broker", "person.* topics")
    ContainerDb(identitydb, "identity DB", "PostgreSQL", "person graph + outbox")
    ContainerDb(searchdb, "search DB", "PostgreSQL", "full-text people index")
    ContainerDb(notifydb, "notification DB", "PostgreSQL", "notifications")
  }

  Rel(user, portal, "Loads SPA", "HTTPS")
  Rel(user, firebase, "Google sign-in (popup)", "HTTPS")
  Rel(portal, people, "Resolve / list / merge (Bearer token)", "HTTPS + CORS")
  Rel(portal, search, "Search people (Bearer token)", "HTTPS + CORS")
  Rel(people, firebase, "Verifies token", "Admin SDK")
  Rel(people, identitydb, "Reads/writes (+ outbox, same tx)", "JDBC")
  Rel(people, kafka, "Outbox relay publishes person.*", "producer")
  Rel(kafka, search, "Consumes (own group)", "consumer")
  Rel(kafka, notify, "Consumes (own group)", "consumer")
  Rel(search, searchdb, "Upsert/remove + search", "JDBC")
  Rel(notify, notifydb, "Create + read notifications", "JDBC")
```

**Proven end-to-end both ways:**
- **Sync path** — Google sign-in → token → portal → people service → database → browser.
- **Event path with fan-out** — resolve a person → outbox (same tx) → broker → **both** Search
  (→ index → portal search) **and** Notifications (→ in-app notification) consume independently
  (separate consumer groups). One event, multiple reactions. Auth enforced everywhere
  (unauthenticated → 403).

**Observability** — every service exposes Prometheus metrics (scraped into Grafana) and reports
errors to Sentry (SaaS). See [ADR-0006](adr/0006-observability-prometheus-sentry.md).

---

## Level 2 — Containers (target state)

Where this is heading, per `PLATFORM-PLAN.md`. Dashed = not built yet.

```mermaid
flowchart TB
  user([User: web / mobile / wearable])
  agent([Agent / MCP])
  firebase[[Firebase Auth — single IdP]]

  subgraph edge[Edge]
    portal[onelifestack-portal]
    comsite[onelifestack.com<br/>marketing SPA]
  end

  subgraph platform[Platform services]
    people[identity-people-service]
    bo[back-office<br/>entitlements]
    spends[Spends]:::planned
    lifelog[LifeLog]:::planned
    ledger[Ledger]:::planned
    vault[Vault]:::planned
    search[search-service]:::planned
    notif[notification-service]:::planned
    mcp[onelifestack-mcp]:::planned
  end

  subgraph backbone[Event backbone]
    kafka[(Kafka / KRaft)]:::planned
  end

  subgraph data[Data — DB per service]
    pgid[(identity DB)]
    pgsp[(spends DB)]:::planned
    pgll[(lifelog DB)]:::planned
  end

  user --> portal
  user --> comsite
  user -.-> firebase
  agent --> mcp
  portal --> people
  portal --> bo
  portal -.-> spends
  portal -.-> lifelog
  people --> firebase
  people --> pgid
  spends -.-> pgsp
  lifelog -.-> pgll
  people -. outbox events .-> kafka
  spends -. outbox events .-> kafka
  kafka -. consumes .-> search
  kafka -. consumes .-> notif
  mcp -.-> people

  classDef planned stroke-dasharray: 5 5,opacity:0.7;
```

Key principles encoded above (see ADRs): Firebase is the **single IdP** ([0001](adr/0001-firebase-single-idp.md));
each service owns its **own DB, no cross-DB joins**, integrating via **events + APIs**
([0003](adr/0003-db-per-service-no-cross-db-joins.md)); Search/Notifications are dedicated consumers
of the event backbone.

---

## Shared-code layering (frontend)

How the client packages stack — platform-agnostic core, then per-platform UI kits, then apps.

```mermaid
flowchart TD
  core["@onelifestack/core<br/><i>auth contract, ApiClient, People/Entitlements clients, design tokens</i><br/>no React / Firebase / RN"]
  uiweb["@onelifestack/ui<br/><i>Firebase web adapter, AuthProvider, Tailwind preset, components</i>"]
  uinative["@onelifestack/ui-native<br/><i>RN adapter, AuthProvider, theme, components</i>"]
  portal["onelifestack-portal (web)"]
  comsite["onelifestack.com (web)"]
  mobile["loggd-mobile / Expo apps"]

  core --> uiweb
  core --> uinative
  uiweb --> portal
  uiweb --> comsite
  uinative --> mobile
```

> Today the apps consume core/ui via local `file:` deps (not yet published) —
> [ADR-0004](adr/0004-file-deps-until-packages-published.md).
