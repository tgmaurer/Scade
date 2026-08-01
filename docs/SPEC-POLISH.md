# Scade — Polish Spec

Follow-up to [SPEC.md](SPEC.md), covering work deliberately deferred until the
app was functionally complete. SPEC.md is a **functional and data** spec and
says so explicitly; this file is the opposite — it's about how the app *feels*
to use. Kept separate so the functional contract that drove phases 1–2 stays
readable as the thing it is.

**Entry condition:** SPEC §4 is implemented and the domain layer is tested.
Met as of commit `c591e0e`.

**Standing constraint for everything below:** this phase changes presentation
and interaction only. No formula, validation rule, sort order, or schema
column changes here. If a section below seems to require one, that's a SPEC.md
amendment, not a polish task — and if it isn't decided yet, it goes in
[SPEC-BACKLOG.md](SPEC-BACKLOG.md).

---

## 0. Prerequisite — manual QA pass

Nothing below should start before the app has actually been *driven*. The
phase-2 screens are compile-verified and launch without crashing, but the
empty states, validation errors, and cascade-delete confirmations have never
been seen on screen.

Walk every screen on macOS and on an iPhone simulator:

- Empty database: each list's empty state, Home with no education, the
  "create disabled with reason" paths (no in-progress education / subject).
- Every form: submit empty, submit over-length, semester above the parent's
  count, grade value 0 and 7, date outside the education's range, duplicate
  subject name+semester. Each should show an inline error, not clamp.
- Delete an education with subjects and grades; confirm the cascade wording
  matches what actually vanishes.
- Home: switch education, apply and clear the semester filter, confirm the
  average moves; quick-add a grade; confirm quick-add is hidden on a
  completed subject.
- Settings: export, then reopen the shared file and confirm it's a valid
  database.

Log what's wrong before fixing anything — a written list keeps this phase
from turning into an open-ended re-write.

---

## 1. Keyboard shortcuts & menu commands (macOS first)

Currently the app has no `Commands` scene at all: no menu items beyond the
system defaults, no shortcuts. On macOS that reads as unfinished regardless
of how the views look.

### 1.1 Navigation

| Shortcut | Action |
|---|---|
| `⌘1`–`⌘5` | Select sidebar section (Home, Educations, Subjects, Grades, Settings) |
| `⌘,` | Settings — the platform convention; on macOS this should open a real Settings scene, not select the sidebar row |
| `⌘[` / `⌘]` | Back / forward in the detail stack |
| `⌘F` | Focus the search field on the current list |

`⌘,` is the one that needs a decision rather than an implementation: SPEC §4
puts Settings in the sidebar, and macOS convention puts it in a separate
window. Options are (a) keep the sidebar row and let `⌘,` select it,
(b) move to a `Settings` scene on macOS and keep the sidebar row on iOS.
(b) is more native and more work.

### 1.2 Records

| Shortcut | Action |
|---|---|
| `⌘N` | New — context-sensitive: new grade on a subject detail, new subject on an education detail, otherwise new record of the current section's type |
| `⌘⇧N` | New education, from anywhere |
| `⌘⌫` | Delete the selected row (still routed through the existing confirmation) |
| `⌘R` | Reload the current screen |
| `⌘S` / `↩` | Save the open form |
| `⎋` | Cancel the open form / dismiss the sheet |

`⌘N` being context-sensitive means the command needs to read the current
selection, which the shell doesn't currently track — see §1.4.

### 1.3 iOS

Full-size keyboard shortcuts also apply to iPad with a hardware keyboard, for
free, if the commands are declared on the shared scene rather than in
`#if os(macOS)`. Prefer that. iPhone gets nothing from this section, which is
fine.

### 1.4 Implementation notes

- Declare via a `Commands` scene on `WindowGroup`, in `ScadeUI`, not in the
  App target — the App target stays a thin shell.
- Menu commands live outside the view hierarchy, so they can't read
  `@State` in a screen. The shell needs a small observable focus/selection
  holder in the environment for `⌘N` and `⌘⌫` to target the right thing.
  Keep it to *what is selected*, not a copy of screen state — the
  no-ambient-state rule from CLAUDE.md applies to UI state too.
- Every shortcut must have a visible menu item. Undiscoverable shortcuts are
  worse than none.

---

## 2. Visual refinement

The current UI is a faithful but plain rendering of the data: stacked `Text`
in default styles, system list rows, no deliberate hierarchy. It's legible
and it's correct; it doesn't look designed.

### 2.1 Identity

- **App icon.** None exists. Needed before this is shippable in any sense.
- **Accent colour.** The app currently inherits the system accent. A chosen
  accent that coexists with the failing-red is the single highest-leverage
  change here — it defines everything downstream.
- **Failing-red** must stay distinguishable from the accent, in both
  appearances, and must keep working with Differentiate Without Color (the
  icon fallback in `GradeValueLabel` already handles this — don't regress it).

### 2.2 Hierarchy in rows

Each list row currently gives near-equal weight to every field. Decide, per
entity, what the eye should land on first:

- Education row: name dominant; institution and date range secondary;
  average as the trailing anchor.
- Subject row: name + semester dominant; parent education secondary; average
  trailing.
- Grade row: value dominant (it's the point of the row); date and
  description secondary; weight tertiary.

The averages and weights already render as badges — that treatment
(`ScadeDesign.badgeCornerRadius`) should become deliberate rather than
incidental: settled sizes, settled contrast, consistent across every screen
that shows one.

### 2.3 Dashboard

Home is the screen most worth designing rather than listing. Currently a
vertical stack of sections. Worth exploring:

- A summary header that reads as a header — education name, average, counts —
  rather than another list section.
- Wide-window layout: subject sections in a grid instead of a single column.
- Some visual signal of progress through an education (semester X of Y is
  data the model already has).

### 2.4 Density and platform fit

- macOS: check window minimum size, sidebar width, and that lists don't look
  stranded in a wide window. Hover and selection states on rows.
- iPhone: verify the split view's collapsed behaviour, that forms are
  reachable above the keyboard, and that swipe actions on rows are what a
  user expects.
- iPad: the middle case; check both orientations and the sidebar toggle.

### 2.5 Motion

No animation is deliberate right now. Additions should be limited to
transitions that explain a change — a row leaving on delete, a value updating
when the filter changes. Nothing decorative.

---

## 3. Accessibility pass

Partly handled already (Differentiate Without Color, Dynamic Type via system
styles). Not verified end to end:

- Dynamic Type at the largest accessibility sizes on every screen — badges
  and single-line rows are the likely breakages.
- VoiceOver: every row should read as one coherent sentence, not a run of
  disconnected labels. Averages should announce "N/A" as "no grades yet" or
  similar, not as three letters.
- Full keyboard navigation on macOS: reachable and visible focus on every
  control, including inside sheets.
- Contrast for the badge treatments in both appearances.

---

## 4. Known gaps, deliberately unresolved

Recorded so they're decisions rather than oversights. None are in scope
unless promoted:

- **Undo.** No undo anywhere; deletes are confirmed-then-permanent.
- **Multi-select / bulk delete.** Single-row operations only.
- **User-controlled sort.** SPEC §3.6 standardises one canonical order per
  entity; there's no UI to change it, by design.
- **Empty-state onboarding.** Empty states explain the state; they don't
  guide a first-time user through education → subject → grade.
- **iCloud sync.** SPEC §5, still deferred. `DatabaseQueue` (no WAL) was
  chosen partly to keep that door open.

---

## 5. Ordering

1. §0 manual QA — produces the actual bug list, which may reorder everything
   below it.
2. §1 keyboard shortcuts — self-contained, testable, and the shell change it
   needs is better made before views are restyled.
3. §2.1 identity (icon, accent) — everything visual depends on it.
4. §2.2–2.5 refinement, screen by screen.
5. §3 accessibility — last, because it's a verification pass over finished
   views, but budgeted, not skipped.
