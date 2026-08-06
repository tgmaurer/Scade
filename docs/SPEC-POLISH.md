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

### 0.1 macOS findings

From driving the macOS app on 2026-08-06. Open until struck through; each one
says which section owns the fix.

- [ ] **Padding and spacing throughout.** Space isn't used or distributed
      well — cramped where it should breathe, and wide windows leave content
      stranded. §2.5, §2.6.
- [ ] **Home stacks a subject's grades vertically**, which eats height for no
      benefit on a screen that has width to spare. Lay them out along the row
      instead, as `gm-home.png` does — improving on it rather than copying it,
      since the old app's version is a bare table. §2.3.
- [ ] **Detail screens are the rawest part of the app.** Every field is the
      same size, and the layout is a stack of ruled rows. They need the §2.4
      ladder and the §2.5 card treatment, which so far only Home has.
- [ ] **The grade list needs separation** — group it into date sections
      rather than presenting one undifferentiated run of rows. §2.4.
- [ ] **Detail screens should link to their parents** — grade → subject →
      education. The data is already on screen as text; it should be
      navigable. §2.4.
- [ ] **Home's semester sections are in the wrong order.** Highest semester
      first. Not a new decision: SPEC §3.6 already specifies semester *desc*,
      and `HomeSemester.grouping` sorted ascending — a regression, not a
      preference.

### 0.1.1 Deferred to a feature pass

Raised during the macOS visual pass but held back deliberately: each one adds
an *action*, not a style, so they belong after the layout has settled rather
than tangled up in it.

- [ ] **A subject row needs an inline "add grade" button**, sitting in the run
      of grades rather than behind a swipe. The swipe action that exists today
      is the iOS answer and a poor one on a pointer.
- [ ] **Each grade chip should link to its grade.** SPEC §4 already lists
      "navigate to grade detail" as a Home action, so this is owed, not new.
      Held back because nesting a link inside a row that also links is exactly
      what made clicking unreliable in the first place — it needs doing once,
      carefully, not bolted on.

### 0.2 How educations are actually used

Context for every layout decision below, from the user's own use of the old
app. **An education is one institution's view of a course of study, not the
course of study itself.** Training as a software developer produced several
educations in parallel — one for the vocational school, one for the
introductory year run by a separate training company, one for the employer —
each with its own subjects and its own grades, because each institution
grades separately.

Consequences that aren't obvious from SPEC.md:

- **Educations overlap in time.** They aren't a sequence, so "the current
  one" is not something the app can infer from dates.
- **Switching education is a frequent, first-class action**, not a rare
  configuration step. It deserves better than a toolbar menu.
- **Comparing across educations is meaningful** — the same person's marks in
  two places at once. Nothing in v1 does this; see
  [SPEC-BACKLOG.md](SPEC-BACKLOG.md) before inventing it.

This is a usage pattern, not a rule. Nothing stops one education per course
of study; the app just shouldn't assume it.

---

## 1. Keyboard shortcuts & menu commands (macOS first)

Currently the app has no `Commands` scene at all: no menu items beyond the
system defaults, no shortcuts. On macOS that reads as unfinished regardless
of how the views look.

### 1.1 Navigation

| Shortcut | Action |
|---|---|
| `⌘1`–`⌘5` | Select tab (Home, Educations, Subjects, Grades, Settings) |
| `⌘,` | Settings — the platform convention; on macOS this should open a real Settings scene, not select the sidebar row |
| `⌘[` / `⌘]` | Back / forward in the detail stack |
| `⌘F` | Focus the search field on the current list |

These bind to the `TabView` selection from §2.2, not to a sidebar — the
shortcuts are unchanged, the thing they set isn't. `⌘5` exists only where
Settings does; on iPhone there is no fifth tab and no hardware keyboard to
press it with.

`⌘,` is the one that needs a decision rather than an implementation: SPEC §4
puts Settings in the sidebar, and macOS convention puts it in a separate
window. Options are (a) keep the sidebar row and let `⌘,` select it,
(b) move to a `Settings` scene on macOS and keep the sidebar row on iOS.
(b) is more native and more work. §2.2 already removes Settings from the tab
bar on iPhone, which makes (b) the smaller step than it was.

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

**Assets live in [`design/`](design/README.md)** — mockups in
`design/mockups/` (the target), GradeMaster screenshots in
`design/reference/grademaster/` (what information a screen needs — a starting
point with known flaws, never a fidelity target, and desktop-only: it says
little about iPhone), other apps in `design/reference/inspiration/`. §2.6 is
where the density and platform-fit decisions it can't answer get made. Read
the relevant image alongside the section below before starting: this document
describes the *problem* on each screen, the references describe what has
already been tried. No mockups exist and none are planned — §2.2 to §2.5 carry
the direction instead, in words.

### 2.1 Identity

- **App icon.** None exists. Needed before this is shippable in any sense.
- **Accent colour.** Indigo, chosen for hue distance from the failing-red.
  Defined in `App/Assets.xcassets/AccentColor.colorset` with light and dark
  variants — **not** as a literal in Swift. The catalog is the only place that
  reaches the app icon tint, the OS's own chrome and any AppKit/UIKit control
  SwiftUI doesn't draw; a code literal colours the view hierarchy and nothing
  else. `ScadeDesign.accent` reads it back, so there's one source of truth.
- **Failing-red** must stay distinguishable from the accent, in both
  appearances, and must keep working with Differentiate Without Color (the
  icon fallback in `GradeValueLabel` already handles this — don't regress it).

### 2.2 Shell and navigation

**Platform priority: macOS and iPhone.** iPadOS is a build target that must
not break, and nothing more — no decision in this document is made for its
sake, and an iPad-only problem gets noted, not fixed.

`RootView` is currently a `NavigationSplitView` on every platform. That's
right on macOS and wrong on iPhone, where it collapses to a stack whose root
*is* the sidebar — switching section means navigating back to a menu, which
no iOS app does.

**Decision: the shell forks per platform.** `NavigationSplitView` with a
fixed-width sidebar on macOS, `TabView` on iOS. Only the shell — every screen
below it is shared, and the selected section is one piece of state both drive.

`TabView(.sidebarAdaptable)` was tried first and does serve both from a single
declaration, rendering as a split view on macOS. It was replaced because it
gives up control macOS needs:

- **The sidebar's width is system-managed**, so it can't be fixed and its
  resize handle can't be removed. Widening it reveals nothing — five rows of
  one word each — so the gesture has no outcome, which is worse than no
  gesture.
- **Each tab gets its own `NavigationStack`**, so the push destinations are
  registered four times instead of once.
- **AppKit draws the sidebar rows**, discarding their accessibility
  identifiers. `ScadeUITests` drives the shell, and had to fall back to
  matching visible titles on macOS.

`navigationSplitViewColumnWidth(_:)` given a single value fixes the width and
removes the handle, which is what settled it.

Tabs, in order: **Home, Educations, Subjects, Grades.**

**Settings is a section only on macOS.** A tab slot is permanent real estate
and Settings is visited rarely; everywhere else it belongs behind a toolbar
button on Home, opening as a sheet. SPEC §4's "Settings in the sidebar" is
honoured where a sidebar exists, which turns out to be macOS alone.

iPad was expected to keep it, on the assumption that `.sidebarAdaptable` would
give iPad a sidebar. **It doesn't.** iPadOS renders a top tab bar, and five
tabs plus its sidebar toggle don't fit an 11-inch portrait window: the bar
paginates, and Settings lands on a second page — present in the accessibility
tree, not reachable by tapping.
`defaultAdaptableTabBarPlacement(.sidebar)` does not override this; it was
tried and had no observable effect. Four tabs fit, so four tabs it is.

#### Recorded alternative — "Library"

Three tabs: Home, Library, Settings — where Library holds a segmented control
switching between Educations, Subjects and Grades.

Not chosen, for reasons worth keeping written down in case the tab bar turns
out to feel redundant in use:

- It costs a tap and adds a mode to remember, to save two tab slots that
  aren't scarce.
- The top of an iPhone list screen already carries a large title and a search
  field (§3.5). A segmented control makes three rows of chrome before any
  content — the opposite of the lean UI it's meant to serve.
- Search would change scope silently underneath a shared field.
- It's a desktop instinct: one panel, many modes. A tab bar *is* the mode
  switcher, so this nests one inside another.

Its real argument — that Educations, Subjects and Grades are one drill-down
chain rather than three peers — is a fair criticism of the flat list model,
inherited from GradeMaster's sidebar. If the flat Grades list proves to be
dead weight on a phone, revisit this then, with usage as evidence.

#### Implementation notes

- Each `Tab` needs its own `NavigationStack`, so the three
  `navigationDestination` registrations in `RootView` get duplicated per tab.
  Factor them into one `ViewModifier` rather than copy-pasting; four drifting
  copies is how a detail screen goes missing on one tab only.
- Tab selection is shell state. Keep it to *which tab*, per the state rule in
  §1.4 — it must not become a second copy of screen state.
- `⌘1`–`⌘5` in §1.1 now map to tab selection rather than sidebar selection.
  Same shortcuts, different binding.
- Accessibility identifiers do **not** survive uniformly, which matters
  because `ScadeUITests` drives the shell. macOS draws sidebar rows in AppKit
  and drops them, exposing a `StaticText` whose *value* is the title; iPhone's
  tab bar keeps the label but not the identifier; iPad's top tab bar keeps
  both. The tests match on identifier-or-label for that reason. The same is
  true of toolbar items that overflow into a "More" menu — iOS rebuilds them
  and the identifier is gone.

### 2.3 Home

The screen most worth designing rather than listing, and the one where the
two platforms genuinely diverge.

**Group by semester.** Today Home renders one `Section` *per subject*, with
that subject's grades inside it. GradeMaster instead used one flat table sorted
by semester, with the semester welded into the row's name (`English - 4`).
Both are wrong in the same way: semester is the unit a student actually
thinks in, and neither gives it structure.

So: a section per semester, headed `Semester N`, with that semester's subjects
as its rows. This also gives the §4 semester filter an honest relationship to
the layout — filtering now narrows to one visible section rather than
reshuffling an undifferentiated list.

**iOS: subject and average only.** One row per subject: name, average badge.
No grade list. Tapping the row opens the subject detail, which already shows
every grade and can add one — so nothing is lost, it moves one tap away. This
keeps the phone screen to the question it's actually asked: *how am I doing?*

Quick-add still needs a home on iPhone once the per-subject section is gone.
A swipe action on the subject row is the native answer; a toolbar `+` is the
fallback. Either way it must stay hidden for a completed subject, per §4.

**macOS: grades stay inline.** There's room, and seeing the grades behind an
average is the point of a desktop dashboard. The wide-window grid idea still
applies — semester cards side by side rather than one column.

> **This changes SPEC §4, which is why it's recorded there too.** §4 lists a
> per-subject grade list as Home data; making that conditional on size class
> is a functional change, not presentation. Amended deliberately, not
> inherited from a picture.

**Also worth doing here:** a summary header that reads as a header — education
name, average, counts — rather than another list section, and some signal of
progress through the education, since `semester X of Y` is already in the
model.

### 2.4 Hierarchy in rows

Each list row currently gives near-equal weight to every field. Decide, per
entity, what the eye should land on first:

- Education row: name dominant; institution and date range secondary;
  average as the trailing anchor.
- Subject row: name + semester dominant; parent education secondary; average
  trailing.
- Grade row: value dominant (it's the point of the row); date and
  description secondary; weight tertiary.

Hierarchy comes from **size and weight before it comes from colour or rules**.
A settled ladder, applied everywhere:

| Role | Treatment |
|---|---|
| The number the screen exists for (education average on Home) | `.largeTitle` or `.title`, `.monospacedDigit()` |
| Row subject | `.headline` |
| Row secondary (institution, parent, date) | `.subheadline`, `.secondary` |
| Metadata (weight, counts) | `.caption`, `.secondary` |

`.monospacedDigit()` on every average and grade value. In a column of numbers
that's the difference between a table and a jitter — and this app is mostly
columns of numbers.

The averages and weights already render as badges — that treatment
(`ScadeDesign.badgeCornerRadius`) should become deliberate rather than
incidental: settled sizes, settled contrast, consistent across every screen
that shows one.

### 2.5 Surfaces and separators

The macOS complaint in one sentence: **too many horizontal lines, not enough
grouping.** Default `List` gives a separator between every row, so a screen
reads as one undifferentiated ruled page — and GradeMaster's detail screens
are the same failure with a border around each block
(`gm-subject_detail.png`: a hairline between every label and value).

The fix is the iOS inset-grouped idea applied deliberately, not more rules:

- **Home groups into cards.** One card per semester, hairlines only *inside*
  a card. Built on `List` rather than the `ScrollView` + `LazyVStack` first
  sketched here: swipe actions are `List`-only, and quick-add needs one on
  iPhone (§4). iOS gets this free from `.insetGrouped`; macOS assembles it —
  `.listStyle(.inset)`, separators hidden, each row on a filled rounded
  rectangle. See `View+GroupedList.swift`.
- **The three flat lists stay `List`s.** They are lists; making every row a
  floating card hurts scanning and fights macOS selection and hover states.
  Reduce the noise instead: `.listRowSeparator(.hidden)`, and let spacing and
  weight do the dividing.
- **Cards are a filled secondary background, not a border.** Contrast against
  the window background with a rounded rect; an outline is the Windows idiom
  visible in the references, and it adds back the lines this section exists to
  remove.
- **No `.glassEffect()` on content.** Liquid Glass is for chrome and controls
  floating *over* content — the tab bar and toolbars get it for free. Putting
  it on a semester card makes the data harder to read and dates the app to one
  release.
- Forms already use `.formStyle(.grouped)` and already look right. That's the
  target texture; match it, don't invent a second one.

### 2.6 Density and platform fit

- macOS: check window minimum size, sidebar width, and that lists don't look
  stranded in a wide window. Hover and selection states on rows.
- iPhone: forms reachable above the keyboard, swipe actions that match
  expectation, and no screen carrying more fields than it needs — see §2.3.
- iPad: supported, not driving. Check both orientations and the sidebar
  toggle; fix what's broken, don't design for it.

### 2.7 Motion

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
2. **§2.2 shell and navigation.** Promoted to the front: it replaces
   `RootView`'s split view with a `TabView`, which every screen sits inside.
   Restyling screens first means restyling them inside a shell that's about to
   change, and it's what makes the app usable on a phone at all.
3. §1 keyboard shortcuts — self-contained and testable. After §2.2, because
   `⌘1`–`⌘5` bind to whatever the shell ended up being.
4. §2.1 identity (icon, accent) — everything else visual depends on the accent
   being settled.
5. §2.3 Home, then §2.4–2.5 across the remaining screens. Home first because
   it's where the semester grouping, the type ladder and the card treatment
   all get decided; the other screens then inherit settled answers.
6. §2.6–2.7 density and motion — passes over finished views.
7. §3 accessibility — last, because it's a verification pass over finished
   views, but budgeted, not skipped.
