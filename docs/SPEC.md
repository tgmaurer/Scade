# Scade — Build Spec

> **Where this stands:** see [STATUS.md](STATUS.md). This document describes
> the goal; that one records where development stopped, and why.

Consolidated spec for the from-scratch SwiftUI rebuild of GradeMaster, merging
architectural decisions with the functional/logic audit of the old app.

This is a **functional and data spec, not a visual spec**. Screens below
describe what data is shown and what a user can do — not layout. Implement
the UI natively for SwiftUI/macOS+iOS idioms.

Visual refinement, keyboard shortcuts, and the accessibility verification
pass are deferred until this spec is fully implemented, and are specified
separately in [SPEC-POLISH.md](SPEC-POLISH.md), with mockups and visual
references in [design/](design/README.md). Behaviour wanted beyond v1 is
collected in [SPEC-BACKLOG.md](SPEC-BACKLOG.md).

---

## 1. Project identity

| | |
|---|---|
| App name | **Scade** |
| App Store subtitle | *Weighted Grade Tracker* (23 chars) |
| GitHub repo name | `Scade` |
| GitHub description | Open-source weighted grade tracker for macOS and iOS. |
| License | GPL-3.0 |
| Platforms | macOS, iOS (single SwiftUI multiplatform target) |
| Stack | SwiftUI, GRDB (raw SQLite, no ORM/change-tracker) |
| Navigation | `TabView` + `.tabViewStyle(.sidebarAdaptable)` — sidebar on macOS, tab bar on iPhone, top tab bar on iPad. Was `NavigationSplitView`; see [SPEC-POLISH.md](SPEC-POLISH.md) §2.2 |
| Grading system | Swiss 1–6 scale (6 = best, 4 = passing), no multi-scale support planned |

Notes and Color are dropped entirely — no equivalent feature in Scade.

---

## 2. Data model

```sql
CREATE TABLE Educations (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL COLLATE NOCASE,
    description TEXT COLLATE NOCASE,
    semesters   INTEGER NOT NULL CHECK (semesters >= 1),
    startDate   TEXT NOT NULL,   -- ISO8601 "yyyy-MM-dd"
    endDate     TEXT NOT NULL,
    institution TEXT COLLATE NOCASE,
    completed   INTEGER NOT NULL DEFAULT 0,
    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE Subjects (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    educationId INTEGER NOT NULL REFERENCES Educations(id) ON DELETE CASCADE,
    name        TEXT NOT NULL COLLATE NOCASE,
    description TEXT COLLATE NOCASE,
    semester    INTEGER NOT NULL CHECK (semester >= 1),
    weight      REAL NOT NULL DEFAULT 1.0 CHECK (weight > 0),
    completed   INTEGER NOT NULL DEFAULT 0,
    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE TABLE Grades (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    subjectId   INTEGER NOT NULL REFERENCES Subjects(id) ON DELETE CASCADE,
    value       REAL NOT NULL CHECK (value >= 1.0 AND value <= 6.0),
    weight      REAL NOT NULL DEFAULT 1.0 CHECK (weight > 0),
    description TEXT COLLATE NOCASE,
    date        TEXT NOT NULL,
    updatedAt   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX idx_subjects_education ON Subjects(educationId);
CREATE INDEX idx_grades_subject ON Grades(subjectId);

-- Closes a gap the old app had: uniqueness was app-code-only, not enforced
-- by the DB, leaving a race-condition window. Enforce it for real this time.
CREATE UNIQUE INDEX idx_subjects_unique ON Subjects(educationId, name, semester);
```

Changes vs. the old schema, for reference:
- `Note`, `Color` tables: **removed**.
- `Weight` table: **removed**. Folded into a plain `REAL` column on both
  `Grade` and (new) `Subject`. Default `1.0` = "counts as one normal
  unit/100%" in both places — this also **removes the old null-coalescing
  logic** (`grade.Weight?.Value ?? 1`), since the column is `NOT NULL
  DEFAULT 1.0` and can never be absent.
- `Subject.weight`: **new column**, doesn't exist in the old app. Scales a
  subject's contribution to its education's overall average (see §3).

---

## 3. Business logic

### 3.1 Subject weighted average

Unchanged in shape from the old app, simplified because weight can no longer be null:

```
if subject has no grades → nil   (display "N/A")
totalWeight = Σ grade.weight
weightedSum = Σ (grade.value * grade.weight)
average = weightedSum / totalWeight
```

### 3.2 Education average rollup — CHANGED

The old app used a plain, unweighted arithmetic mean of subject averages,
which is exactly the gap that motivated adding `Subject.weight`. New formula:

```
qualifyingSubjects = subjects with ≥1 grade   (subjects with 0 grades are
                                                 excluded, not treated as 0 —
                                                 same as old behavior)
if qualifyingSubjects is empty → nil   (display "N/A")
totalWeight = Σ subject.weight  (for qualifying subjects)
weightedSum = Σ (subjectAverage * subject.weight)  (for qualifying subjects)
educationAverage = weightedSum / totalWeight
```

Since `weight > 0` is DB-enforced and at least one qualifying subject exists
whenever this runs, `totalWeight` can never be zero here — no div-by-zero
guard needed in that branch.

**Architecture note:** the old app had this formula duplicated verbatim in
two files (`SubjectUtils` and an unused copy in `EducationUtils`). Implement
once, in a single shared calculation type (e.g. a `GradeCalculator` struct/
enum with static functions), used by every screen that needs an average.

**Sentinel note:** the old app used `0` as a magic "no data" return value,
relying on the fact that 0 is outside the valid 1–6 grade range. Use `nil`
(`Double?`) instead — it's the same information without relying on an
implicit out-of-range convention, and Swift's optionals make "no data yet"
explicit at every call site rather than something the caller has to
remember to special-case.

**Bug to not repeat:** the old app once computed an average from a lazily-
loaded, un-populated navigation collection and silently got 0/wrong results
(fixed in commit `14f4d15`). Whatever data-loading pattern GRDB uses, always
compute averages from an explicitly, fully-fetched set of grades/subjects —
never from an object graph that might be partially loaded.

### 3.3 Rounding & display formatting

- No rounding is applied at storage time — store exactly what the user
  enters (subject to the CHECK constraints above).
- Display formatting only, standardized to **one consistent format across
  the whole app** (the old app inconsistently mixed `"0.##"` and `"0.0##"`
  in different views — pick one and use it everywhere):
  - Grade values & computed averages: 2 decimal places, e.g. `5.25`.
  - Weight: display as a percentage (`125%`, `50%`) computed from the raw
    multiplier, since that reads more naturally to a user than a raw
    decimal — store the multiplier, format for display only.
- "No grades yet" → display **"N/A"**, driven by the `nil` sentinel from
  §3.2/3.1, not a `0` value.

### 3.4 Validation rules

- **Education**: name required ≤255, description ≤2500, semesters ≥1,
  start/end date required, **end date ≥ start date** (cross-field check,
  enforce in Swift form validation — no DB constraint for this one since
  SQLite CHECK can't easily reference two columns' relative order... actually
  it can (`CHECK (endDate >= startDate)`) — include it as a DB-level
  guarantee too, not just UI validation).
- **Subject**: name required ≤255, description ≤2500, semester ≥1, weight
  >0. **Semester ≤ parent education's `semesters`**: recommend rejecting
  with an inline field error rather than the old app's silent-clamp-and-
  toast pattern — clamping user input without them asking for it is
  surprising; a form error they can see and fix is more predictable.
  Duplicate (education, name, semester): now enforced at the DB level via
  the unique index in §2, not just app code.
- **Grade**: value required, **1–6** (drop the old app's inconsistent `Min=0`
  UI relic — the DataAnnotation `[Range(1,6)]` was always the real rule, the
  0-minimum was dead/unreachable code, not an intentional design choice).
  Weight >0. Subject required. **Date within parent education's
  [startDate, endDate]**: same recommendation as above — inline validation
  error instead of silent clamping. Description **optional**, ≤2500, like
  the other two — made required on 2026-08-21 and reverted the next day; see
  [SPEC-BACKLOG](SPEC-BACKLOG.md) §5 for why.
- Completion state: only settable via edit, never at creation (both
  Education and Subject are always born "in progress") — preserved as-is,
  it's a reasonable rule.
- `value < 4` remains the universal "failing" threshold for red/warning
  styling on grades and averages (Swiss convention: 4 = passing).

### 3.5 Search & filtering

Search and filtering are separate, deliberately simple mechanisms — not a
combined query grammar.

**Search** (all list screens): plain substring match via
`localizedCaseInsensitiveContains` against name + description, and (for
Subjects/Grades) the parent entity's name. No embedded syntax, no numeric
or completion-state parsing inside the search text. Filtering in Swift
rather than SQL `LIKE` also means accented characters are matched
correctly and case-insensitively, unlike SQLite's ASCII-only `NOCASE`.

**Filter controls** (separate UI element, not part of the search field):
- Educations, Subjects: completion state (All / In Progress / Completed),
  institution (picker of distinct values present in current data)
- Subjects: semester (bounded numeric filter, same pattern as the Home
  screen's existing semester filter)
- Grades: a "failing only" (<4) quick toggle

No institution-suffix search syntax, no `(ip)`/`(c)` text suffixes, no
trailing-integer semester/value parsing inside search text — all of that
functionality is covered by the dedicated filter controls instead.

### 3.6 Sorting — standardize instead of porting inconsistencies

The old app used different orderings for the same data on different screens
(grades oldest-first on Home but newest-first everywhere else; subjects with
three different tiebreaker orders across three screens). Recommend picking
**one canonical order per entity type, used everywhere**:
- Grades: **newest-first** (date desc, then id desc) — matches the majority
  of existing screens.
  - **One exception, decided later: the run of grades inside a subject's row
    on Home reads oldest-first.** The premise changed. When this section was
    written, Home stacked a subject's grades vertically, where newest-first is
    right for the same reason it is in every list — the most recent is the one
    you came to see, and it belongs at the top. SPEC-POLISH §2.3 turned that
    stack into a horizontal run, and a horizontal sequence of dated values is
    read as a timeline: left to right is earlier to later, so newest-first
    puts it backwards.
  - This is not the old app's inconsistency coming back. That one had the same
    *vertical* list ordered two ways on two screens with no reason. This is
    one ordering for lists and one for a timeline, which is a difference in
    what the reader is being shown, not in which screen they're on.
- Subjects: **semester desc → name asc → id desc** — matches Home's
  ordering, apply it on every screen that lists subjects.
- Top-level lists (Educations/Subjects/Grades list screens): newest-created
  first (id desc), unaffected by search.

---

## 4. Screens (functional spec — data & actions, not layout)

### Home / Dashboard
**Data:** selected education (with completion indicator); subject count and
grade count for it; education-level weighted average (§3.2) or "N/A";
optional semester filter indicator; subjects grouped by semester; per-subject:
name, subject average badge, and — in a regular width only — that subject's
grade list (value + weight, styled red if value <4).
**Per-subject grades are width-dependent.** In compact width (iPhone) a
subject row shows its name and average and nothing else; the grades are one
tap away in the subject detail, which already lists them all. This is the only
place in the spec where a screen's data varies by platform, and it's
deliberate: a phone-sized dashboard answers "how am I doing", and inlining
every grade behind every subject turns that into a wall of numbers. Rationale
and layout consequences: [SPEC-POLISH.md](SPEC-POLISH.md) §2.3.
**Actions:** pick education; filter by semester (bounded 0–education's
semester count); clear filter; create education/subject/grade (prefilled
with current education + filtered semester where applicable); reload;
navigate to subject/grade detail; quick-add grade per subject (hidden if that
subject is completed — in compact width this is a row action rather than a
button inside the subject's section, since there is no section).
**Behavior:** filter control disabled until an education is picked; "new
subject" disabled with reason if education is completed; averages recompute
on every relevant state change (education switch, filter apply/clear,
reload).

### Educations — List / Detail / Create-Edit
**List data:** name, start/end year, institution, description, computed
average, total semesters, completion state, subject count. Search (§3.5).
**Detail data:** everything from the list card plus full description, and
the full list of that education's subjects.
**Create/Edit fields:** name*, institution, start date*, end date*, total
semesters* (≥1), completed (edit-only), description.
**Defaults on create:** the school year containing today — 1 August to 31
July — semesters = 2, completed = false. Before August that means the year
which began the *previous* August, so the range always contains today.
That's load-bearing, not cosmetic: §3.4 requires a grade's date to fall
within its education's range, so a default range that started in the future
would reject a grade dated today for the seven months from January to July.
These are still only defaults; an education may span any range where
`endDate >= startDate`.
**Actions:** create, edit, delete (confirm — mention subject count and that
related subjects/grades cascade-delete), search, navigate to detail.

### Subjects — List / Detail / Create-Edit
**List data:** name + semester, parent education (name, institution,
completion), description, subject weighted average, "semester X of Y",
weight, completion state, grade count. Search (§3.5).
**Detail data:** everything from the list card plus full grade list for
that subject.
**Create/Edit fields:** name*, education* (dropdown — in-progress
educations only, except the subject's current education is always included
when editing even if completed by then), semester* (bounded 1..education's
semester count), weight* (default 1.0/100%), completed (edit-only),
description.
**Query-param-equivalent prefill:** when created from an education context,
education is pre-selected/locked, and semester pre-filled if a filter was
active.
**Actions:** create (disabled with reason if no in-progress education
exists anywhere), edit, delete (confirm — mention grade count, cascades),
search, navigate to detail.

### Grades — List / Detail / Create-Edit
**List data:** value (styled red if <4), weight (as % and raw), description,
parent subject (name, semester, completion) and education (name,
institution, completion), date. Search (§3.5).
**Create/Edit fields:** value* (1–6), weight* (preset quick-picks + custom
numeric entry — see below), subject* (dropdown — in-progress subjects only,
except current subject always included when editing), date*, description.
**Weight input:** since `Weight` is no longer its own table, offer a picker
with the old preset values as quick-picks (100, 90, 87.5, 80, 75, 70, 66.7,
62.5, 60, 50, 40, 37.5, 33.3, 30, 25, 20, 12.5, 10 — as %), plus a free
numeric field for anything else. Purely a UI convenience now, not a DB
constraint.
**Defaults on create:** date = today.
**Actions:** create (disabled with reason if no in-progress subject exists
anywhere), edit, delete (confirm), search, navigate to detail.

### Settings
Carrying forward only what's actually relevant to the new app (the old
Windows-specific OneDrive-path-switching/override machinery has no
equivalent need in a SwiftUI/iCloud-native app):
- Theme (light/dark/system).
- Backup / export (share the SQLite file via the system share sheet).
- iCloud sync toggle (see §5) — if/when implemented.
- Static info/FAQ content, if you still want it.
- No CRUD UI for weight presets — same as the old app, presets are a fixed
  quick-pick list, not user-editable data (in Scade, "editable" is trivial
  anyway since it's just a free numeric field, so this isn't a limitation
  the way it was when Weight was a real DB table).

---

## 5. iCloud sync (design notes, from earlier discussion)

Recommended approach: **file-level sync** via the app's iCloud ubiquity
container (`FileManager.url(forUbiquityContainerIdentifier:)`), matching the
"fully local, happens to sync" model you referenced (Awesome Habits-style),
not full CloudKit record sync.

Two things to get right:
- **Force a WAL checkpoint** (`PRAGMA wal_checkpoint(TRUNCATE)`) before the
  file is allowed to sync, or avoid WAL mode for this file — otherwise
  iCloud may sync the main DB file without its `-wal`/`-shm` sidecars and
  corrupt the copy on another device.
- **Wrap reads/writes in `NSFileCoordinator`/`NSFilePresenter`** so the sync
  system doesn't pull the file out from under an open connection.
- Known limitation to accept, not solve: conflicts are file-level, not
  row-level — acceptable for a single-user personal app that's rarely
  mid-edit on two devices simultaneously.

---

## 6. Open decisions — confirm or override before this goes to build

Everything below has a stated default baked into the spec above. Flagging
them explicitly so you can override anything before handing this to
Claude Code / starting the build:

1. **Silent-clamp vs. inline error** for semester-exceeds-max and
   date-outside-education-range (§3.4): spec defaults to inline error,
   old app silently clamped + toasted.
2. **Sort order standardization** (§3.6): spec picks one canonical order
   per entity; confirm the specific orders chosen are the ones you want.
3. **Search implementation** (§3.5): spec recommends in-Swift filtering
   over SQL LIKE, partly to fix the accent-case-sensitivity bug for free.
4. **Grade min value = 1, not 0** (§3.4): spec treats the old `Min=0` UI
   bound as an unintentional bug, not a design decision to preserve.
5. **Weight display as %** vs. raw multiplier (§3.3) — spec defaults to %.
6. **`nil` sentinel instead of `0`** for "no grades yet" averages (§3.2) —
   internal representation change, no user-visible difference ("N/A"
   either way).
7. **Settings scope** (§4) — confirm which of Theme/Backup/iCloud
   toggle/static info pages you actually want in v1 vs. later.

---

## 7. Explicitly out of scope

- Notes feature, Color entity — dropped, no replacement planned.
- Multiple grading-scale support (e.g. German 1-best system) — not in this
  spec; schema stores raw numeric values so it's not blocked structurally,
  but no UI/settings for it is planned here.
- Windows/MAUI-specific settings machinery (OneDrive path switching, DB
  override, version-check) — no equivalent, iCloud sync (§5) replaces the
  underlying need.
