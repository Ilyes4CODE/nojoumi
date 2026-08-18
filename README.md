# نجومي — Nojoumi

Android parental-control and educational-motivation app for the Algerian market.
Turns screen time into a currency the child earns by studying, rather than a privilege a parent withdraws.

**Read [CLAUDE.md](CLAUDE.md) before touching anything.** `docs/contract.pdf` and its appendix are the source of
truth; every number in them is a contractual obligation.

## Status

| Piece | State |
|---|---|
| Plan, conventions, contract obligations | done |
| Android behaviour verification, round 1 | done — [docs/android-behaviour-notes.md](docs/android-behaviour-notes.md) |
| `packages/nojoumi_time` — trusted clock (Art. 6.8, 7.6) | **21 tests green** |
| `packages/nojoumi_stars` — star engine (Art. 5, 6, appendix) | **89 tests green** |
| Kotlin blocking spike | not started — the day-2 gate |
| Everything native | **unverified: no test device yet** |

Nothing in the native layer has run on hardware. "Compiles" is not "works".

## Layout

```
docs/        contract, appendix, decisions, verification notes, Art. 12 checklist
packages/    pure Dart contract logic — no Flutter, no platform, no clock reads
app/         Flutter app (not scaffolded yet)
native/      Kotlin modules (not scaffolded yet)
server/      Django REST API (not scaffolded yet)
spike/       throwaway Kotlin blocking spike (not scaffolded yet)
```

## Running the tests

```powershell
cd packages\nojoumi_time  ; dart pub get ; dart test
cd packages\nojoumi_stars ; dart pub get ; dart test
```

Both are pure Dart — no device, no emulator, no network. That is deliberate: Articles 5, 6 and 7 are where the
contract is most precise, so they are made provable without hardware.

## Toolchain on the dev machine

Flutter 3.41.5 · Dart 3.11.3 · Android SDK platforms 33–36.1 · `minSdk 29`, `target/compileSdk 36`.

`java` on PATH is JDK 8, which Gradle will reject. Point `JAVA_HOME` at Android Studio's bundled runtime:

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

## Key documents

- [CLAUDE.md](CLAUDE.md) — conventions, architecture decisions, obligations that must never be violated
- [docs/decisions.md](docs/decisions.md) — every open question, how it was resolved, what is still pending
- [docs/blocking-checklist.md](docs/blocking-checklist.md) — the 12 Article 12 scenarios, re-run on hardware daily
- [docs/android-behaviour-notes.md](docs/android-behaviour-notes.md) — which documented platform behaviour we rely on
