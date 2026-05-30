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

What's **actually deployed** in a k3s dev cluster today . This is the first vertical slice.

```mermaid
C4Container
  title Containers — Live slice (a k3s dev cluster, dev)

  Person(user, "User", "Browser")

  System_Ext(firebase, "Firebase Auth", "single IdP (dev project)")

  System_Boundary(ols, "OneLifeStack (a k3s dev cluster, )") {
    Container(portal, "onelifestack-portal", "React + Vite SPA on nginx", "Launcher + People center + Account. Built on @onelifestack/ui + /core")
    Container(people, "identity-people-service", "Spring Boot 3.4 / Java 21", "Canonical People graph: resolve, suggestions, reversible merge/unmerge")
    ContainerDb(identitydb, "identity DB", "PostgreSQL 17", "person, person_link, person_match_candidate, person_merge_log. Own database")
  }

  Rel(user, portal, "Loads SPA", "HTTPS")
  Rel(user, firebase, "Google sign-in (popup)", "HTTPS")
  Rel(portal, people, "Calls (Bearer ID token)", "HTTPS + CORS")
  Rel(people, firebase, "Verifies token", "Admin SDK")
  Rel(people, identitydb, "Reads/writes", "JDBC")
```

**Proven end-to-end:** Google sign-in → Firebase token → portal → CORS → people service → Postgres →
back to the browser. Auth is enforced (unauthenticated `/api/v1/people` → 403).

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
