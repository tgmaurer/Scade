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

- [x] ~~**Home stacks a subject's grades vertically**~~ — laid out along the
      row instead. `FlowLayout` + `GradeChip`. §2.3.
- [x] ~~**Home's semester sections are in the wrong order.**~~ Highest first.
      Not a new decision: SPEC §3.6 already specifies semester *desc*, and
      `HomeSemester.grouping` sorted ascending — a regression, not a
      preference. `Dictionary(grouping:)` has no defined order; the grouping
      now preserves the query's.
- [x] ~~**Separators drawn where nothing needs separating.**~~ The list ruled a
      line above a card's first row, below its last, and across the full list
      width rather than the card's. Cards draw their own dividers now, inset to
      their content — see §2.5.
- [x] ~~**Subject rows changed height with their contents.**~~ A row with no
      grades sat shorter than one with chips in it. §2.5.
- [x] ~~**The subject link claimed more than the subject name.**~~ §2.8.
- [ ] **Padding and spacing throughout.** Space isn't used or distributed
      well — cramped where it should breathe, and wide windows leave content
      stranded. §2.5, §2.6.
- [ ] **Detail screens are the rawest part of the app.** Every field is the
      same size, and the layout is a stack of ruled rows. They need the §2.4
      ladder and the §2.5 card treatment, which so far only Home has.
- [ ] **The grade list needs separation** — group it into date sections
      rather than presenting one undifferentiated run of rows. §2.4.
- [ ] **Detail screens should link to their parents** — grade → subject →
      education. The data is already on screen as text; it should be
      navigable. §2.4.
- [ ] **Hover on the three flat lists** is still whatever macOS gives a
      full-row `NavigationLink`. Deliberately left until those screens are
      restyled rather than guessed at against a layout that's about to
      change. §2.8. *Educations and subjects done — both answer the pointer
      the way a card row does, which each got by being restyled onto one.
      Grades outstanding.*
- [x] ~~**The subjects list spent four lines saying two lines' worth.**~~ The
      institution was printed in full on every row — it belongs to the
      education, not the subject, and repeating "gibb, Gewerblich Industrielle
      Berufsfachschule Bern" down the list said nothing about any subject in
      it. The semester had a line to itself when §2.4 puts it beside the name.
      The weight read "100%" on every row, which is the absence of weighting
      announcing itself — `WeightLabel.isMeaningful` now decides, the rule
      `GradeChip` already had. §2.4, §2.5.
- [x] ~~**The educations list wasted a wide window and separated nothing.**~~
      One column of plain text in a window three columns wide, with the
      system's own row separator drawn between records in place of any
      grouping — and drawn wrong, inset to somewhere near the middle of the
      row rather than to anything on screen. Now a grid of card tiles. §2.5.

### 0.1.1 Deferred to a feature pass

Raised during the macOS visual pass but held back deliberately: each one adds
an *action*, not a style, so they belong after the layout has settled rather
than tangled up in it.

- [x] ~~**A subject row needs an inline "add grade" button**, sitting in the
      run of grades rather than behind a swipe.~~ `AddGradeButton`, at the end
      of the flow so it wraps with the chips. The swipe stays for the phone,
      where §2.3 shows no grades and so leaves no row to put a button in.
      Not a new action — SPEC §4 already has quick-add; this is a better way
      to reach it. Its **absence** is now how a completed subject reads as
      completed, which costs no badge and no colour (§2.4).
- [x] ~~**Each grade chip should link to its grade.**~~ SPEC §4 already listed
      "navigate to grade detail" as a Home action, so this was owed, not new.
      Held back at first because nesting a link inside a row that also linked
      was what made clicking unreliable — and that caution turned out to be
      right for a reason worse than expected: several `NavigationLink`s in one
      macOS `List` row destroy its layout outright. `GradeChipButton`, §2.8.

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

**Two rungs of the ladder side by side are centred, not baseline-aligned.** A
shared baseline is right for text of similar size and wrong once the gap is
large: it pins the smaller thing's bottom to the larger one's, so every bit of
slack collects above it and the smaller thing reads as having slipped down the
row. Home's summary header is the case — a `.title2` name beside a
`.largeTitle` average — and centring splits the space evenly. Where the
smaller side is a stack, only the rung being compared belongs in the aligned
row; the rest goes underneath, or there is nothing to centre.

The same goes for a *run* of things at different heights — a subject's grade
chips, the label that stands in for them when there are none, the button that
adds one. `FlowLayout` centres each item on its line rather than hanging them
from the top, which is what left "No grades" riding above the chip beside it.

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
  rectangle. See `View+GroupedList.swift` and `CardRow.swift`.
- **A card draws its own dividers; the list draws none.** Turning the list's
  separators off row by row isn't enough and was the source of three separate
  faults: the line above a section's first row comes from the *section*, not
  its rows, and the ones that did appear ran the full width of the list
  instead of stopping at the card. So on macOS every system separator is off
  and the divider is drawn in the row's background, held back from the card's
  edges by `cardDividerInset`. It lives in the background rather than the row
  content because it belongs to the card, not to either of the rows it
  divides — it has to survive whichever one the pointer is over.
- **Rows in one card are all the same height.** A row with no grades has no
  chips to give it height and would otherwise sit shorter than its neighbours,
  which reads as two different kinds of row. The floor is *derived* from the
  chip height (`ScadeDesign.subjectRowHeight`), not chosen to match it: a
  floor the chips exceed is not a floor, which is how the two drifted apart
  the first time.
- **The long flat lists stay `List`s.** Subjects run to dozens and grades to
  hundreds; those are read down a column, and making every row a floating card
  hurts scanning and fights macOS selection and hover states.

  They still get the card *surface*, though — **one card holding the whole
  list**, not one per row (amended 2026-08-11; this bullet originally said to
  hide the separators and let spacing and weight do the dividing, which was
  written before Home had proved the card treatment). One card is what
  replaces the system separators, and it's what iOS's own `.insetGrouped`
  does with a single long section, so it isn't a Mac invention. It also brings
  the row hover with it, which is the §0.1 item those lists were waiting on.

  The distinction that matters is **one card of many rows** versus **many
  cards of one row each**. The first is a list with a surface under it; the
  second is a grid, and needs the cardinality above to earn it.
- **A row is capped in width; a tile is not** (`ScadeDesign.maximumRowWidth`).
  Past about 900pt a row stops being read as one thing: the name is at one end
  of the screen and its average at the other, with nothing in between. Capping
  keeps the pair within a glance and turns the leftover into a margin instead
  of a hole. Leading-aligned, not centred, so the card stays lined up with the
  window title rather than drifting rightwards as the window grows. A row with
  something to put in the middle — the dashboard's, whose grade chips fill it
  — is exempt, which is why the cap is an argument to `cardRow` and defaults
  to off.
- **What goes hard right is the number, and only the number.** Everything else
  on a line follows the text before it. Pinning secondary metadata to the
  trailing edge as well leaves a word at each end of a wide row and a void
  between them; a continuous phrase is read far more easily than a gap is
  crossed. The average is the exception because a column of numbers is the one
  thing on these screens worth aligning — which is what `.monospacedDigit()`
  in §2.4 exists to serve.
- **Educations are the exception, and get a grid** (amended 2026-08-11;
  this section originally said all three lists stay lists). There are a
  handful of them — several run in parallel, one per institution — so the
  reasoning above doesn't apply: there is no long column to scan and nothing
  to scroll past, so a single column left most of a wide window empty while
  still not showing more. Tiles in a `CardGrid`, one to three columns by
  width, capped at three because past that a tile is too narrow to hold a name
  and an average on one line and the eye starts scanning a field of boxes
  rather than reading a short list. Column count is also capped by the item
  count, so two educations are two half-width tiles rather than two-thirds of
  a row with a hole beside them.

  **Every tile in a grid row is as tall as the tallest one in it**, which
  makes any field that can grow a cost paid by every education beside it. Two
  rules, and they answer different halves of the problem:

  - **A tile's last block is pushed to the bottom, not stacked under the
    first.** Spare height collects in the middle, so the counts and status
    line up across the whole grid row instead of each trailing off wherever
    its own text ran out — which is better than merely not looking broken.
    Where there's no spare height, as in the iOS list row, the gap collapses
    to ordinary row spacing and the layout is the stack it always was.
  - **Every growable field is bounded**, because bottom-alignment stops dead
    space but not growth: names are capped at 255 characters, which is some
    nine lines at tile width, and one such tile would drag its whole row
    down. How tight the bound is depends on what the field is *for*. The
    institution is held to one line, since the record is identifiable without
    it. The name gets two, because it's what identifies the education and
    nothing else on the tile repeats it — "Informatiker EFZ
    Applikationsentwicklung" one-lined is indistinguishable from
    "Informatiker EFZ".

  Where one line carries two things of different lengths, the long one gives
  way and the short one is pinned (`.fixedSize()`). The years beside an
  institution are four digits; putting both in one string would have let the
  ellipsis eat the years first.

  **The grid is earned by cardinality, not by the screen being a list.** Two
  questions decide it, and both have to point the same way:

  1. **Is there a scanning task?** With a handful of records there isn't —
     they're all on screen at once, so a two-axis layout costs nothing. With
     dozens there is, and a list wins: every name starts at the same x and the
     eye follows one edge, where a grid makes it zigzag between two or three.
  2. **Is there a column worth aligning?** In a list every average is
     right-aligned in one vertical column and the outlier is visible without
     reading. A grid scatters them across two axes and comparing becomes
     hunting. Educations are the case where this doesn't apply: an average at
     one institution against an average at another isn't a comparison anyone
     makes, so there's nothing to line up.

  Educations answer "no" and "no" — a few objects you pick between. Subjects
  and grades answer "yes" and "yes" — many records you scan and compare. That
  the old app used cards for all three is not evidence: it used cards for
  everything, which is a template applied uniformly rather than a decision
  made per screen, and CLAUDE.md limits that reference to content and
  priority, "never for density or layout".

  And the tile here is not
  GradeMaster's card (`gm-educations-list.png`): no stroked outline, no
  `Label: value` rules inside the tile, and no action buttons on it — the
  whole tile is the way in to the detail, and delete is a context menu.
- **Separation comes from the surface, not from a rule.** The complaint that
  opened this section applies within a screen as well as across it: a list of
  educations that were only text had nothing marking where one ended and the
  next began, and a hairline between them would have been the same mistake at
  a smaller scale. A card is what separates two records; a rule inside a card
  is what separates two rows of the same record.
- **A tile carries the same surface as a card row** — `CardTile` and
  `CardRowSurface` fill the same secondary background at the same radius, and
  light the same way under the pointer. One card, not two that nearly match.
  What differs is only what a tile doesn't need: no divider, and all four
  corners rounded, because it has no neighbour above or below.
- **Swipe to delete doesn't survive the grid, and shouldn't.**
  `.swipeActions` is `List`-only, so a grid can't carry it — but it was an iOS
  gesture on a Mac to begin with, and the macOS answer is a context menu. iOS
  keeps its `List` and its swipe. Neither is the only way out: the detail
  screen has a Delete of its own.
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
when the filter changes. Nothing decorative. Hover transitions (§2.8) are the
exception that proves it: ~120ms, only so the highlight doesn't snap.

### 2.8 Pointer states

macOS has a pointer and the app should answer it. Nothing on the dashboard
looks like a control — it's a table of names and numbers — so hover is what
tells someone a thing can be clicked *before* they click it.

**Everything that responds is a button, and looks like one.** Not a link.
Background shifts under the pointer; text colour and decoration stay put:

- **The row** takes a wash of `rowHoverFill` over the card fill. This is the
  "where am I" cue, and it's why the divider had to move into the background:
  a hovered row and its neighbour must stay separated.
- **A record's title** gets a filled rounded rect behind it. The fill is
  padded *outwards* from the text so the title doesn't shift and every row on
  screen isn't indented to reserve room for a highlight that's usually
  invisible.
- **A grade chip** steps from `controlFill` to `controlHoverFill` — it already
  has a background, so it brightens rather than growing a second one. Two
  stacked fills read as a third colour, so `GradeChip` owns both strengths
  instead of having a highlight layered over it.

**Two strengths, and controls get the louder one.** `controlHoverFill` is two
steps up the hierarchy from rest, not one: at one step the change was there
but easy to miss, which is no use for a cue whose whole job is to be noticed
*before* anything is clicked. The row's wash stays faint deliberately — a
row-wide highlight as strong as a button's drowns the button inside it.

**A row that doesn't lead anywhere doesn't light up.** The summary card is
figures with a single control in it, so the card itself takes
`highlightsOnHover: false` and only the education's name responds. Lighting
the whole card would promise a click that does nothing.

**No `.pointerStyle(.link)`.** The pointing hand is a *web* convention that
macOS reserves for navigation leaving the app. Using it for an in-app push
promises a browser. Internal navigation keeps the arrow — the background
change is the whole affordance. Accent-coloured or underlined text is out for
the same reason: that's what a link looks like, and none of these are links.

**None of them is a `NavigationLink` either**, which is a layout constraint
rather than a style one. macOS `List` gives a row containing one a
presentation of its own, and a row containing *several* is destroyed by it —
the name and every chip each took a full-width line, the chips lost their
backgrounds, the average vanished, and nothing navigated. One link per row
survives; more do not. So the dashboard's controls are `Button`s that push
through `Navigator`, and the three flat lists keep `NavigationLink` because
there the whole row is the link, which is the case `List` handles well.

**A control claims its own content and nothing more.** The subject button is
exactly as wide as the name it draws; a `.frame` around it reserves the
column. That works because a `.frame` outside a `Button` positions it without
extending what's clickable — widening the target takes a `contentShape`, and
that one is on the text.

**Nothing in a dashboard row may have an infinite ideal width.** The name is
served first (`layoutPriority(1)`), so a greedy view there takes the whole row
and leaves the grades and average nothing to lay out in. This broke the screen
twice, both times through a `Spacer` placed beside the button to "absorb the
rest of the column" — a stack containing a `Spacer` has an infinite ideal
width, which is the opposite of absorbing anything. The symptoms didn't look
like a width problem: chips wrapped one per line and lost their backgrounds,
"No grades yet" wrapped into a tall invisible column, and the average
disappeared off the edge. `HomeSubjectRowLayoutTests` now measures the row and
fails on all of it.

On a phone the button keeps its width but takes a 44pt height, since a finger
can't hit a word. The width is left alone on both platforms — widening it is
what costs the average its place.

**The sidebar is `List(selection:)` and a `Label`, and nothing else.**

It was briefly hand-drawn, to stop the selection grey-ing out when focus moves
to the detail column. That greying is `NSTableView` emphasis and genuinely has
no SwiftUI hook — but replacing the row to get at it cost four things, three
of them invisible until someone used the app:

- **The full-row click target.** A button fills the row's *content*; the
  insets around it belong to the row, so the margins were dead.
- **Hover.** macOS doesn't hover sidebar rows; that highlight was ours.
- **Every metric** — row height, insets, where a selection sits. Restating
  them meant the text sat further right than macOS puts it, the rows grew, and
  the selection was first too narrow and then edge-to-edge.
- **Section switching itself.** The selection binding is not decoration: it's
  how a `NavigationSplitView` learns the detail column should be replaced, and
  it takes the detail's navigation stack back to its root as part of that.
  Hand-drawn rows set the same state, but the split view never heard about it,
  so the stack kept whatever was pushed — choosing a section from a detail
  screen swapped the root *underneath* it and looked like nothing happened
  until you navigated back.

That last one is the lesson worth keeping. A system control is often load
bearing in ways its appearance doesn't advertise, and this one was carrying
the app's navigation. `testSwitchingSectionFromADetailScreenLeavesIt` pins it:
it fails against the hand-drawn sidebar and passes against this one.

The selection greys out when the detail column has focus, as it does in Mail
and Xcode. If that has to change, it is a deliberate trade against the four
above and not a styling tweak.

**Hover is state, so it needs a view.** A `View` extension has nowhere to keep
`@State`; each of the three is a `ViewModifier` or a small view of its own
(`CardRow`, `SubjectButton`, `GradeChipButton`). Hover propagates to
ancestors, so a chip and its row light together — which is correct: they're
nested targets and both are live.

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
- **Multi-select / bulk delete.** Single-row operations only. Raised again
  when the educations grid was designed, and still out of scope — but noted
  there as the one action that would justify putting selection on a list
  screen at all, since every other operation belongs to a single record and
  is reachable from its detail. If it's ever promoted, the grid is where it
  lands, and macOS selection semantics (⌘-click, ⇧-click, Delete key) are the
  contract to meet — not a row of checkboxes.
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
