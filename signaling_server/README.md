# signaling_server

Reference implementation of the pairing relay described in
`../docs/PAIRING_MIGRATION.md`. Standalone Dart project, zero runtime
dependencies (uses only `dart:io`), deliberately kept dependency-free
so it's directly runnable.

## Running locally

```
cd signaling_server
dart pub get      # only resolves local test dependency, no network needed for the server itself
dart run bin/server.dart 8080
```

## Running the tests

```
dart test
```

Covers `InviteStore`'s lifecycle logic (creation, uniqueness, expiry,
single-use completion) directly, without spinning up real HTTP/WebSocket
connections. The relay/routing logic in `bin/server.dart` itself isn't
unit-tested here — it's thin (parse request, delegate to `InviteStore`,
forward bytes) and would need an integration-test harness spinning up
a real `HttpServer` to test meaningfully, which wasn't built this pass.

## What this server does and does not do

See `PAIRING_MIGRATION.md` section 5 for the precise responsibility
list. Short version: generates invite IDs, matches exactly two
WebSocket connections per invite, relays whatever they send each other
without inspecting it beyond routing, enforces a 10-minute TTL, and
deletes the invite the moment both sides report their direct P2P
connection is up. It never touches chat content or private keys — it
has no code path that could, since it never receives them (see the
signaling message protocol in
`lib/features/pairing/domain/entities/signaling_message.dart` on the
Flutter side for exactly what does cross this server).

## Deploying this for real

This reference implementation is intentionally minimal — before
running it as real infrastructure for real pairings, at minimum add:

- **TLS.** This binds plain `HttpServer` — put it behind a reverse
  proxy (nginx, Caddy) or use `SecurityContext` with
  `HttpServer.bindSecure` directly for `wss://`/`https://`. An
  unencrypted relay leaks the exact metadata this design already
  accepts leaking to the *operator* of the server (see
  PAIRING_MIGRATION.md section 3) to literally anyone on the network
  path as well, which is strictly worse.
- **Rate limiting on `POST /invites`**, to prevent someone spamming
  invite creation.
- **A persistent invite store** if you need more than one server
  process/instance — `InviteStore` is in-memory only; horizontally
  scaling this server as-is would require invites to be visible across
  instances (Redis with TTL support is a natural fit, matching the
  existing 10-minute-expiry model).
- **Structured logging and monitoring** — this reference
  implementation only writes to stdout/stderr.
- **A real domain + hosting** for `https://pair.twoperson.app` if you
  want the `https://` Universal-Link/App-Link form of the invite (in
  addition to, or instead of, the `twoperson://` custom scheme, which
  needs no server-hosted verification file and works with this server
  as-is). The `https://` form additionally requires hosting an
  `.well-known/apple-app-site-association` file (iOS) and a
  `.well-known/assetlinks.json` file (Android) on that domain — this
  is a domain-ownership-verification mechanism, not something this
  reference server can do on your behalf.
