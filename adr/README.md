# Architecture Decision Records (ADRs)

Short, immutable records of significant decisions — the **why** behind the architecture, captured
where it versions with the code. One file per decision. Don't edit an accepted ADR's decision; if it
changes, write a new ADR and mark the old one `Superseded by`.

New decision → copy [`0000-template.md`](0000-template.md), take the next number, fill it in.

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-firebase-single-idp.md) | Firebase as the single IdP for all clients | Accepted |
| [0002](0002-adc-vs-sealed-sa-key.md) | Firebase creds: ADC for local, sealed SA key in k3s | Accepted |
| [0003](0003-db-per-service-no-cross-db-joins.md) | DB-per-service, no cross-DB joins; integrate via events + APIs | Accepted |
| [0004](0004-file-deps-until-packages-published.md) | Shared frontend packages via `file:` deps until published | Accepted (interim) |

> More decisions worth backfilling as ADRs over time: Kafka + outbox as the event backbone;
> dedicated Search + Notifications services; production hosting choices; strangler-by-domain
> decomposition.
