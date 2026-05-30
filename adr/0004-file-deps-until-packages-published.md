# ADR-0004: Consume shared frontend packages via local `file:` deps until published

- **Status:** Accepted (interim)
- **Date:** 2026-05-30
- **Deciders:** solo dev (OneLifeStack)

## Context

The web apps depend on `@onelifestack/core` and `@onelifestack/ui`. Publishing them to GitHub
Packages needs a `write:packages` PAT (not yet provisioned) plus prep (they're `"private": true`;
`/ui` depends on core). We wanted the portal building and deployed *now* without blocking on that.

## Decision

Consume the shared packages via local **`file:../../platform/...`** dependencies for now. Build
Docker images from the **onelifestack root** so the linked packages are in context, and use
**`npm install --install-links`** (copies the deps as real packages rather than symlinking).

## Alternatives considered

- **Publish to GitHub Packages first** — the "right" long-term answer, but blocked on the PAT + prep;
  would have stalled the deploy. Deferred, not rejected.
- **npm/pnpm workspaces (monorepo)** — but the repos are intentionally **separate git repos** with
  their own remotes; a workspace would fight that structure.
- **Default npm symlinking of `file:` deps** — breaks in Docker: TS/Node resolve `react` and the
  `ui→core` import from the symlink's real path, which has no `node_modules`. Hence `--install-links`.

## Consequences

- The portal builds and deploys today without a registry.
- The Docker build carries four workarounds (layout mirroring, root `.dockerignore`, explicit
  `dist/` copy, `--install-links` + `preserveSymlinks`); also added a `default` export condition to
  `@onelifestack/ui` for CJS config loaders. All documented in the internal deployment runbook.
- **This is interim.** When the PAT exists, publish core/ui, drop `"private": true`, swap `file:` →
  versioned deps, and remove the Docker workarounds. Tracked as a pending prereq.
