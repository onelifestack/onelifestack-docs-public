# ADR-0003: Database-per-service, no cross-DB joins; services integrate via events + APIs

- **Status:** Accepted
- **Date:** 2026-05-29
- **Deciders:** solo dev (OneLifeStack)

## Context

The platform is decomposed by domain (identity/people, spends, lifelog, ledger, vault, search,
notifications, …). A shared monolithic database would couple services at the schema level, block
independent deploys, and make a later move to managed Postgres per service painful. The
canonical People graph in particular must be queryable by every app without those apps reaching into
its tables.

## Decision

**Each service owns its own database**; Flyway manages its schema; `ddl-auto: validate`. **No
cross-database joins.** Services integrate only via (a) **published events** (Kafka + transactional
outbox per service) and (b) **typed APIs**. Apps keep their own person rows but call the People
service to resolve a canonical `person_id`.

## Alternatives considered

- **Shared database, schema-per-module** — simpler ops short-term, but couples deploys and schemas;
  hard to split later. Rejected.
- **Direct synchronous calls only (no events)** — creates runtime coupling and fan-out failure modes;
  events give loose coupling + let Search/Notifications consume without the producer knowing them.

## Consequences

- Clean service boundaries; each DB can move to managed Postgres independently.
- No joins across services → some data is denormalized/duplicated and reconciled via events
  (eventual consistency); the People service is the resolver, not a foreign key.
- Requires the event backbone (Kafka + outbox) and discipline about contracts. Until that lands,
  services integrate via APIs only (`PeopleClient.resolve`).
- In dev, the services still physically share one Postgres instance but use
  **separate logical databases** — the boundary is preserved, the instance is not.
