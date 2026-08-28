# Scade

SwiftUI grade tracker for macOS/iOS. Full spec: docs/SPEC.md — read it before
starting any feature work.

## Documentation map
- `docs/SPEC.md` — the v1 functional contract. What the app does.
- `docs/STATUS.md` — where development stopped and why. Read it before
  proposing work: iOS and iCloud sync are frozen, not pending.
- `docs/SPEC-POLISH.md` — look and feel; presentation and interaction only.
- `docs/SPEC-BACKLOG.md` — behaviour that isn't built and isn't v1.
- `docs/design/` — mockups and visual references. See its README for what
  lives where; read the relevant image before starting a SPEC-POLISH §2 task.
- `screenshots/` — gitignored scratch space for screenshots taken while
  working on the UI. Write them here, never into the repo proper: git keeps
  every revision of a binary forever. Anything worth keeping goes in
  `docs/design/` deliberately.

## Non-negotiables
- **Platforms: macOS and iPhone.** iPadOS is a build target that must not
  break, and nothing more. Never make a design decision for its sake, never
  open a debugging thread on an iPad-only symptom, and don't spend
  verification runs on it — note the problem and move on.
- No ORM change-tracking. GRDB only, explicit queries, no ambient state.
  GRDB's own `ValueObservation` is *not* what this forbids, and screens use it
  through `AppDatabase.observe`: the query is one you wrote and it is re-run
  whole, with nothing tracked per object, no graph and no cache. What's banned
  is a layer that watches objects and decides for you what changed.
- Business logic (averages, validation) lives in
  `ScadeKit/Sources/ScadeKit/Logic/`, is unit tested, and is never
  duplicated across call sites.
- If GradeMaster (old MAUI app) is in context: reference for business logic,
  data shape, and — from `docs/design/reference/grademaster/` — what
  information belongs on a screen. Never for project structure, architecture,
  or MAUI control idioms; that's what this rewrite exists to leave behind.
  Take what it shows, not how it was built.
- GradeMaster's UI is a starting point, never a fidelity target. Assume it
  carries flaws and non-native idioms. Ask what a screen is trying to tell the
  user, then do that the best way for macOS/iOS — improving on it is the
  expected outcome, matching it is not. It's a *desktop* reference: on iPhone
  and iPad use it cautiously, for content and priority only, never for density
  or layout.
- Mockups in `docs/design/mockups/` are the visual target, but they do not
  amend SPEC.md. An image implying a new field, rule, or sort order is a
  SPEC-BACKLOG item, not a licence to build it.

## Conventions
- [testing requirements, formatting, whatever you land on]
