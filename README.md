# Lunio

Android parental-control and educational-motivation app for the Algerian market.
Turns screen time into a currency the child earns by studying, rather than a privilege a parent withdraws.

**Read [docs/CONVENTIONS.md](docs/CONVENTIONS.md) before touching anything.** `docs/contract.pdf` and its appendix are the source of
truth; every number in them is a contractual obligation.

## Status

| Piece | State |
|---|---|
| Plan, conventions, contract obligations | done |
| Android behaviour verification, round 1 | done — [docs/android-behaviour-notes.md](docs/android-behaviour-notes.md) |
| `packages/lunio_time` — trusted clock (Art. 6.8, 7.6) | **21 tests green** |
| `packages/lunio_stars` — star engine (Art. 5, 6, appendix) | **89 tests green** |
| `packages/lunio_subscription` — five-state machine (Art. 7) | **42 tests green** |
| `packages/lunio_sm2` — spaced repetition (Art. 2, 4) | **46 tests green** |
| Django — lesson AI proxy (Art. 14) | **81 server tests green** |
| Django — accounts + JWT (Art. 3) | included above |
| Django — devices, trial-once-per-device (Art. 7.1) | included above |
| Django — subscriptions, 5 states, Ed25519 signed snapshot (Art. 7.6) | included above |
| Django — payments, webhook idempotency (Art. 7.3, 7.7) | included above |
| Chargily Pay v2 — checkout + signed webhook | **31 tests green**, real HMAC (decisions.md D-35) |
| Chargily webhook delivery | **blocked — needs a public HTTPS URL (Q19)** |
| OpenAPI/Swagger schema (Art. 19 deliverable) | 10 endpoints, 0 errors |
| Flutter app scaffold (`dz.lunio`, minSdk 29, target 36) | done |
| **Android build** — debug APK and release AAB | **both build** (decisions.md D-37) — unsigned, debug keys |
| Illustrations — 7 assets, delivered and wired | **0.19 MB of WebP** (budget 1 MB) |
| Launcher icon — legacy + adaptive, from the client's logo | done |
| API client, parent auth (JWT), lesson capture + save | **10 tests green** |
| Capture / review / lessons / account screens | done — **UNVERIFIED-ON-HARDWARE** |
| Weekly test + Article 14 automatic deletion (criterion 11.6) | **19 tests green** |
| Subscription — Ed25519 snapshot verified cross-language (Art. 7.6) | **8 tests green** |
| Subscription / trial / activation-code screens | done — **UNVERIFIED-ON-HARDWARE** |
| Arabic/English l10n, RTL default | 204 keys, `ar` + `en`, `ar` pinned as the locale |
| Drift local schema — 18 tables, all child data local (Art. 14) | **15 tests green** |
| Repositories — settings, trusted clock, star ledger, daily session | **46 tests green** |
| Parent PIN — PBKDF2 salted hash, never recoverable (D-10) | **5 tests green** |
| App shell — RTL, `ar` pinned, routing, theme | **12 widget tests green** |
| Daily session — cards, questions, SM-2, bonuses (Art. 4.3, 5, 6) | **10 widget tests green** |
| Setup wizard + Play disclosure & parental consent | done — **UNVERIFIED-ON-HARDWARE** |
| Child home screen — balance, play time, clock warning | done — **UNVERIFIED-ON-HARDWARE** |
| Clock MethodChannel (Kotlin `LunioClock`) | written — **UNVERIFIED-ON-HARDWARE** (notes V9) |
| Session screen — commit-then-reveal, measured time on task | done — **UNVERIFIED-ON-HARDWARE** |
| Parent dashboard — PIN gate, grant/deduct, pause, the six settings, ledger | **11 widget tests green** |
| Managed-apps picker, blocked card, launcher grid | **wait on the Kotlin layer** |
| Native modules (`native/`), blocking spike | not scaffolded |
| Code generation (`build_runner`) | **unblocked** — 21 outputs in 33 s from the ASCII path (decisions.md D-31) |
| Kotlin blocking spike | not started — **the first thing the device does** |
| Everything native | **unverified: no test device yet** |
| Art. 12 scenarios 9 and 10 | **contractually unresolved** — awaiting the client's written reply to `docs/client-letter-scenarios-9-10-ar.md` |

Nothing in the native layer has run on hardware. "Compiles" is not "works".

## Layout

```
docs/        contract, appendix, decisions, verification notes, Art. 12 checklist
packages/    pure Dart contract logic — no Flutter, no platform, no clock reads
app/         Flutter app (Arabic RTL) + Drift local database
native/      Kotlin modules (not scaffolded yet)
server/      Django REST API + the lesson AI proxy
spike/       throwaway Kotlin blocking spike (not scaffolded yet)
```

## Running the tests

```powershell
cd packages\lunio_time         ; dart pub get ; dart test
cd packages\lunio_stars        ; dart pub get ; dart test
cd packages\lunio_subscription ; dart pub get ; dart test
cd packages\lunio_sm2          ; dart pub get ; dart test
```

Server:

```powershell
cd server ; python manage.py test apps
```

**419 tests, all green** (198 pure Dart + 112 Python + 109 app), none of them needing a phone. The 99 app tests
split in two: 66 run against real SQLite in plain `test()` bodies, and 33 are widget tests over provider
overrides with no I/O at all — see decisions.md D-33 for why that separation is not optional.

## Code generation

```powershell
cd app ; dart run build_runner build
```

Needed after any change to `lib/data/local/tables.dart` or `database.dart`. **The project path must stay ASCII** —
a non-ASCII path breaks the AOT snapshot the builder writes (decisions.md D-31). `--delete-conflicting-outputs`
is accepted but ignored by this build_runner; do not rely on it.

First-time server setup:

```powershell
cd server
copy .env.example .env          # then fill in GROQ_API_KEY and GROQ_MODEL
python manage.py migrate
python manage.py generate_signing_key   # private half -> .env, public half -> the app
python manage.py runserver
```

API docs at `/api/docs/`, schema at `/api/schema/`.

## Toolchain on the dev machine

Flutter 3.41.5 · Dart 3.11.3 · Android SDK platforms 33–36.1 · `minSdk 29`, `target/compileSdk 36`.

`java` on PATH is JDK 8, which Gradle will reject. Point `JAVA_HOME` at Android Studio's bundled runtime:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

## Key documents

- [docs/CONVENTIONS.md](docs/CONVENTIONS.md) — conventions, architecture decisions, obligations that must never be violated
- [docs/decisions.md](docs/decisions.md) — every open question, how it was resolved, what is still pending
- [docs/blocking-checklist.md](docs/blocking-checklist.md) — the 12 Article 12 scenarios, re-run on hardware daily
- [docs/android-behaviour-notes.md](docs/android-behaviour-notes.md) — which documented platform behaviour we rely on
- [docs/design-v4.md](docs/design-v4.md) — **current** visual direction, from the client's second design set: palette,
  the seven illustration prompts, and the seven settings ranges that contradict the signed appendix
- [docs/design-v3.md](docs/design-v3.md), [docs/design-v2.md](docs/design-v2.md) — superseded, kept for the reasoning
- [docs/screen-prompts.md](docs/screen-prompts.md) — 46 prompts, one per screen, splash to payment page
- [docs/hardware-verification.md](docs/hardware-verification.md) — what to run the day the reference device arrives
