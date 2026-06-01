# OneLifeStack — Engineering Docs

Public engineering documentation for **OneLifeStack** — a connected life platform that helps
people preserve, understand, and grow what matters most: relationships, memories, identity,
experiences, and life story.

> *Your story. Connected.*

Built by a solo developer and reached through web, native mobile, wearables, and AI agents — on
one identity and a canonical **People graph**.

Public-facing editorial surface:
- `blog.onelifestack.com`
- `studio.onelifestack.com`

> This is the **public** subset — architecture, design decisions, and the engineering story.
> Operational details (deployment, infrastructure, business setup) live in a separate private repo.

## Contents

| Doc | What it is |
|---|---|
| [Platform overview](platform-overview.md) | Vision, principles, and the architecture at a glance |
| [Architecture (C4)](architecture.md) | C4 / Mermaid diagrams — system context, container view, frontend layering |
| [Decisions (ADRs)](adr/README.md) | Architecture Decision Records — the *why* behind key choices |

## The idea in one paragraph

Most software organizes data. OneLifeStack organizes life. Apps are lenses into a connected life
graph (people, events, memories, spending, relationships) — not standalone products. One human =
one identity across every surface and app. Sign in once (Firebase as the single IdP), and a
canonical People graph resolves "the same person" across apps — with user-confirmed, reversible
merges, never silent. Each domain is its own service with its own database (no cross-DB joins),
integrating through events and typed APIs. Shared frontend logic lives in a platform-agnostic core
with thin per-platform UI kits, so web, native, and agents share one identity model and design
language.
