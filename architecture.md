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
    System(platform, "OneLifeStack", "Connected life platform: identity/people, memory, finance, productivity, documents, search, notifications, MCP agents")
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

## Level 2 — Containers (live as of 2026-06-05)

All services below are deployed in a homelab k3s dev cluster. Each owns its own database; no
cross-DB joins — services integrate via events and typed APIs only.

```mermaid
flowchart TB
  user([User: browser])
  agent([Agent / MCP])
  firebase[[Firebase Auth — single IdP]]

  subgraph edge[Edge / clients]
    portal["onelifestack-portal\nReact + Vite SPA on nginx\nLife Timeline · Today · Memories\nFinances · My Legacy · People · Templates"]
    comsite["onelifestack.com\nmarketing SPA"]
    blog["onelifestack-blog\nSanity CMS blog"]
  end

  subgraph platform[Platform services — all LIVE]
    people["identity-people-service\nCanonical People graph\nresolve · merge · AccessGrant\nonboarding · AI settings"]
    memory["memory-service\nMemories as graph nodes\nJournal · Trip · Milestone\nOn This Day"]
    productivity["productivity-service\nHabits + confidence %\none-tap Today"]
    finance["finance-service\nICICI import · transactions\ncategorization + enrichment"]
    ledger["ledger-service\nAssets · Liabilities · Net worth\n15 types · People graph links"]
    document["document-service\nDocument metadata + upload\nserver-side storage (PVC/Drive)"]
    template["template-service\nQuick-capture template marketplace\ncurated + community templates"]
    search["search-service\nPostgres FTS · owner-scoped\nconsumes person.* events"]
    notif["notification-service\nin-app notifications\nconsumes person.* events"]
    mcp["onelifestack-mcp\nMCP stdio server · 12 tools\nbuilt + image pushed · not yet deployed"]
  end

  subgraph backbone[Event backbone]
    kafka[(Kafka KRaft)]
  end

  subgraph data[Data — DB per service]
    pgid[(identity DB)]
    pgmem[(memory DB)]
    pgprod[(productivity DB)]
    pgfin[(finance DB)]
    pgled[(ledger DB)]
    pgdoc[(document DB)]
    pgtpl[(template DB)]
    pgsearch[(search DB)]
    pgnotif[(notification DB)]
  end

  user --> portal
  user --> comsite
  user --> blog
  agent --> mcp
  portal --> people
  portal --> memory
  portal --> productivity
  portal --> finance
  portal --> ledger
  portal --> document
  portal --> template
  portal --> search
  portal --> notif
  people --> firebase
  people --> pgid
  memory --> pgmem
  productivity --> pgprod
  finance --> pgfin
  ledger --> pgled
  document --> pgdoc
  template --> pgtpl
  search --> pgsearch
  notif --> pgnotif
  people -. "person.* outbox events" .-> kafka
  memory -. "memory.* outbox events" .-> kafka
  productivity -. "habit.* outbox events" .-> kafka
  kafka -. consumes .-> search
  kafka -. consumes .-> notif
  mcp --> people
  mcp --> search
  mcp --> notif
```

**Key cross-cutting wiring:**
- All backend services authenticate via Firebase Admin SDK (shared `onelifestack-backend-firebase` k8s secret).
- Commons Spring Boot starter (`onelifestack-commons`) provides: auth filter, error envelope, CORS, audit logging, outbox/event relay — zero reimplementation per service.
- `memory-service` and `ledger-service` call `identity-people-service /resolve` to link named people into the canonical graph.
- `ledger-service` calls `identity-people-service /check` to enforce AccessGrant-based access for non-owners.

---

## Level 2 — Containers (target state)

Near-term additions: MCP deployment, mobile client, SpendStack migration, LifeLog decomposition.

```mermaid
flowchart TB
  user([User: web / mobile / wearable])
  agent([Agent / MCP])
  firebase[[Firebase Auth — single IdP]]

  subgraph edge[Edge]
    portal[onelifestack-portal]
    comsite[onelifestack.com]
    mobile[Expo mobile app]:::planned
  end

  subgraph platform[Platform services]
    people[identity-people-service]
    memory[memory-service]
    productivity[productivity-service]
    finance[finance-service]
    ledger[ledger-service]
    document[document-service]
    template[template-service]
    search[search-service]
    notif[notification-service]
    mcp[onelifestack-mcp]:::planned_deploy
    health[health-service]:::planned
    knowledge[knowledge-service]:::planned
    places[places-service]:::planned
  end

  subgraph backbone[Event backbone]
    kafka[(Kafka / KRaft)]
  end

  user --> portal
  user -.-> mobile
  agent --> mcp
  portal --> people & memory & productivity & finance & ledger & document & template & search & notif
  mobile -.-> people
  people --> firebase
  people & memory & productivity -. outbox events .-> kafka
  kafka -. consumes .-> search & notif & mcp
  mcp --> people & search & notif & finance & ledger & memory

  classDef planned stroke-dasharray: 5 5,opacity:0.6;
  classDef planned_deploy stroke-dasharray: 3 3,opacity:0.8;
```

---

## Shared-code layering (frontend)

How the client packages stack — platform-agnostic core, then per-platform UI kits, then apps.

```mermaid
flowchart TD
  core["@onelifestack/core v0.4.0\nauth contract · ApiClient · design tokens\nPRESETS (life/life-nocturne/platform)\nPeople/Memory/Finance/Ledger/Productivity\nDocument/Template/Search/Notification clients\nno React / Firebase / RN"]
  uiweb["@onelifestack/ui v0.3.0\nFirebase web adapter · AuthProvider\nTailwind preset (applyPreset, --ols-* + --ols-graph-*) · components"]
  uinative["@onelifestack/ui-native v0.1.0\nRN adapter · AuthProvider · theme"]
  portal["onelifestack-portal (web) v0.7.0"]
  comsite["onelifestack.com (web) v1.22.0"]
  mobile["Expo mobile (planned)"]:::planned

  core --> uiweb
  core --> uinative
  uiweb --> portal
  uiweb --> comsite
  uinative -.-> mobile

  classDef planned stroke-dasharray: 5 5,opacity:0.6;
```

All three packages are published to GitHub Packages (`npm.pkg.github.com`) and consumed via
versioned registry deps. See [ADR-0004](adr/0004-file-deps-until-packages-published.md).

---

## Backend service pattern

Every backend service follows the same shape, enforced by `onelifestack-commons`.

```mermaid
flowchart LR
  client[Client\nbrowser / portal] -->|Bearer Firebase token| filter[FirebaseAuthFilter\ncommons]
  filter --> controller[Controller\nthin]
  controller --> service[Service\nbusiness logic]
  service --> repo[Repository\nSpring Data JPA]
  repo --> db[(own DB\nPostgres)]
  service -->|within @Transactional| outbox[OutboxEvent\ncommons]
  outbox --> relay[OutboxRelay\ncommons @Scheduled]
  relay --> kafka[(Kafka)]
```

Key properties: stateless (no sessions), constructor injection only, Flyway migrations,
`ddl-auto: validate`, `CurrentUser.require()` for ownership scoping.
