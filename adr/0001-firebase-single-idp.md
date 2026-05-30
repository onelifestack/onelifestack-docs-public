# ADR-0001: Firebase as the single identity provider for all clients

- **Status:** Accepted
- **Date:** 2026-05-29
- **Deciders:** solo dev (OneLifeStack)

## Context

OneLifeStack is reached through many surfaces — web, native mobile (Expo), wearables, and agents
(MCP) — and many apps (Spends, LifeLog, Ledger, Vault, …). Every surface needs authentication, and
the platform's premise is *one human = one identity everywhere*. Re-implementing auth per app, or
running multiple IdPs, would fragment identity and multiply security surface.

## Decision

Use **Firebase Authentication as the single IdP** for all clients. The Firebase UID is the universal
identity key across the whole platform. Separate dev and prod Firebase projects under the business GCP org. Backends verify Firebase ID tokens centrally via
`onelifestack-commons`; clients obtain tokens via platform UI kits (web: Firebase JS SDK; native:
`@react-native-google-signin`).

## Alternatives considered

- **Roll our own auth** (e.g. Spring Security + JWT, OAuth2 server) — full control, but large
  security/ops burden for a solo dev; reinventing token issuance, refresh, social login.
- **Auth0 / Clerk / Cognito** — capable, but more cost at scale and less aligned with the existing
  GCP/Firebase footprint; Firebase gives Google sign-in + token verification cheaply.

## Consequences

- All services inherit auth from commons (`FirebaseAuthFilter`, `CurrentUser`) — no per-app auth code.
- A Firebase **service-account key** (or ADC) is needed to *verify* tokens server-side — see
  [ADR-0002](0002-adc-vs-sealed-sa-key.md).
- Browser-facing apps must add their host to Firebase **authorized domains** or sign-in fails.
- Vendor coupling to Firebase/Google; mitigated by keeping the auth contract abstract in
  `@onelifestack/core` (`AuthAdapter`) so the client side isn't hard-wired to Firebase.
