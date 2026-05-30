# ADR-0005: Search engine — Postgres full-text search (not a dedicated engine)

- **Status:** Accepted
- **Date:** 2026-05-30
- **Deciders:** solo dev (OneLifeStack)

## Context

The Search service consumes domain events and owns a search index (apps never write it directly).
It needed a search engine. Decision point "P-search": a dedicated engine (Elasticsearch/OpenSearch,
Meilisearch, Typesense) vs. **Postgres full-text search** (`tsvector` + GIN). The first use is
owner-scoped people search (name/email) at small scale; the platform already runs Postgres, and
DB-per-service ([ADR-0003](0003-db-per-service-no-cross-db-joins.md)) means the Search service owns
its own database regardless.

## Decision

Use **Postgres full-text search** — the Search service owns its own DB with a `person_search` table
carrying a generated `tsvector` column (+ GIN index), queried with `websearch_to_tsquery`. No new
search infrastructure. (The `simple` text config is used so short names aren't stemmed/stop-worded.)

## Alternatives considered

- **Meilisearch / Typesense** — excellent search UX (typo-tolerance, instant, ranking), but a new
  stateful service to run, back up, and operate. Not justified for people search at this stage.
- **Elasticsearch / OpenSearch** — most powerful, heaviest footprint (JVM, memory). Overkill now.

## Consequences

- Zero new infrastructure; the engine is just another table in a service-owned database. Fits the
  DB-per-service model cleanly.
- Good enough for name/email people search; owner-scoping is a simple `WHERE` clause.
- Tradeoff: no built-in typo-tolerance or advanced relevance tuning. Acceptable for now.
- **Revisit** (a dedicated engine) only if ranking quality, typo-tolerance, or scale demand it —
  the Search service is a clean seam to swap the engine behind without touching producers.
- Note: the native FTS query is Postgres-specific, so it's verified against a real database (and the
  live round-trip) rather than the in-memory test database used for the projection logic.
