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
- [x] ~~**Padding and spacing throughout.** Space isn't used or distributed
      well — cramped where it should breathe, and wide windows leave content
      stranded.~~ §2.5, §2.6. The cramped half was settled over the August
      padding passes. The wide-window half was open longest and is settled
      **by splitting it** (2026-08-27): the three grid lists are capped at
      1400pt and centred, chosen so a 14" MacBook Pro never sees the cap;
      Home and the detail screens stay full width by decision, because they
      read as documents rather than grids. *What that leaves unfixed, on
      purpose: a card as wide as the window on Home and the education detail
      still puts a subject's name at one end and its average at the other.*
- [x] ~~**Detail screens are the rawest part of the app.** Every field is the
      same size, and the layout is a stack of ruled rows.~~ All three rebuilt
      2026-08-21 on one structure: `ScrollView` + `DetailSection`, a
      selectable identity card carrying the §2.4 ladder, `CardRowLink` for
      any row that navigates, and a `DetailButton` for each parent. See
      §2.4's "a detail screen is not a table of its fields" and §2.5's "a
      detail screen is a document".
- [x] ~~**The grade list needs separation**~~ — it was one undifferentiated
      run of rows, and it's now a grid of tiles, so each grade is its own
      object on its own surface. *Date sections were the fix proposed here
      and are **not** what was built:* sectioning by date requires the list
      to be sorted by date, and it is sorted `id desc` like the other two
      top-level lists (SPEC §3.6). That's a sort-order change, which this
      phase commits to not making — so it stays open as
      [SPEC-BACKLOG](SPEC-BACKLOG.md) §4, where it is now the only half of
      this finding still outstanding. §2.5.
- [x] ~~**Detail screens should link to their parents** — grade → subject →
      education. The data is already on screen as text; it should be
      navigable.~~ Done 2026-08-21, as `DetailButton`s on each identity card.
      The whole chain is navigable now, and the grade — being the bottom of
      it — links to both. This was impossible until the `Navigator` fix
      earlier the same day: a pushed screen never received one, so the button
      would have run its action and gone nowhere. §2.4.
- [x] ~~**Hover on the three flat lists** is still whatever macOS gives a
      full-row `NavigationLink`.~~ Deliberately left until those screens were
      restyled rather than guessed at against a layout that was about to
      change — and the restyle settled it without a decision to make: all
      three are grids of tiles now, and a tile answers the pointer itself.
      §2.8.
- [x] ~~**A pressed row lit up outside its own card.**~~ macOS draws a link
      row's pressed state as an accent fill across the whole row, while the
      card behind it is inset by the window margin — so pressing lit two
      accent strips either side of the card and nothing under it. Any full-row
      `NavigationLink` on a card has this; the grids avoid it by construction,
      since a plain button in a grid has no such presentation to give up.
      §2.8.

      *Struck through too early (2026-08-11), and it came back on the
      education detail: "the grids avoid it" was true and "it is fixed" was
      not, because a card of link rows was still reachable — a detail
      screen's sub-list is exactly that. Two things were also **wrong** in
      the note as first written: `.buttonStyle(.plain)` does not take the
      fill away (it belongs to the row, not to the label inside it), and the
      earlier subjects-list "fix" that claimed it did was never doing
      anything — the grid is what fixed that screen. The fill is now avoided
      the only way that works: the row is a `Button`, not a link
      (`CardRowLink`).*
- [x] ~~**The subjects list spent four lines saying two lines' worth.**~~ The
      institution was printed in full on every row — it belongs to the
      education, not the subject, and repeating "gibb, Gewerblich Industrielle
      Berufsfachschule Bern" down the list said nothing about any subject in
      it. The semester had a line to itself when §2.4 puts it beside the name.
      The weight read "100%" on every row, which is the absence of weighting
      announcing itself — `WeightLabel.isMeaningful` now decides, the rule
      `GradeChip` already had. §2.4, §2.5.
- [x] ~~**Home clipped its own rows.**~~ Two symptoms, one cause. Filtering to
      one semester adds a line to the summary card, and the row kept its old
      height, so the new line was cut in half. Launching on a **non-Retina
      display** gave *every* row roughly half the height it needed, clipping
      each one mid-word — and dragging the window to a Retina display and
      back fixed it, which is what a stale cached height looks like from the
      outside. **A macOS `List` decides a row's height once and does not
      re-measure it.** Both reproduced on demand (2026-08-21, second display
      at 1×) and both gone with Home rebuilt as `ScrollView` + `DetailSection`
      — the same cards the detail screens are made of. Nothing in the app is
      a `List` on macOS now except the sidebar. §2.5.
- [x] ~~**A typed space was invisible in a form field.**~~ macOS's grouped
      `Form` anchors a labelled field's text to its *trailing* edge, and a
      trailing space has no mark of its own and doesn't move the anchor — so
      the row is pixel-for-pixel identical before and after the keystroke,
      and the space reads as dropped until the next character lands and the
      whole string jumps left by two. Typing "Modul 4" showed `Modul`,
      `Modul`, `Modul 4`. Free text now reads from the left
      (`FormTextField`); the numeric fields keep the trailing alignment,
      which is the point of them. §2.4.
- [x] ~~**Switching section flashed the empty state.**~~ An observation is
      asynchronous, so each screen was briefly on screen with empty arrays in
      it and "Nothing to Track Yet" drawn over them. Every list model now
      says whether its first snapshot has arrived. §2.7.
- [x] ~~**Settings was a sidebar row.**~~ Its own window on macOS now, on
      `⌘,` and in the app menu. §1.1, §2.2.
- [x] ~~**The window was called "Subjects", with nothing to say whose.**~~
      Built as "Scade – Subjects" at a section root, then **reverted the same
      day**: the app switcher shows the icon, so the name is the one thing
      already answered, and on macOS the window's title *is* the toolbar's —
      one string, no API separating them — so the prefix was paid for twice
      on screen to solve a problem that wasn't there. Closed as won't-do, not
      as done. §2.2.
- [x] ~~**Card rows lost height when Home stopped being a `List`.**~~ A
      `List` row adds a few points of its own around whatever it's given and
      a card row doesn't, so moving the padding out to the container took 8pt
      off every dashboard row. `cardRowVerticalPadding` puts it back, and the
      detail screens — built as cards from the start, so short by the same
      amount all along — get it too.
- [x] ~~**Section headers stopped sticking.**~~ A regression from the same
      change: a `List` pins its section headers and a `VStack` has nothing to
      pin. `DetailScroll` is a `LazyVStack(pinnedViews: .sectionHeaders)`, and
      making it work forced a shape on everything above it — see §2.5.
- [x] ~~**A form's free text began in the middle of the sheet.**~~ Fixing the
      invisible space moved the text from the trailing edge to the leading
      edge of a field that `LabeledContent` had already placed halfway across
      the row, so a name started in the middle with nothing in front of it.
      A label column puts it back where a form's text belongs: just after the
      word naming it, in the same place on every row. §2.4.
- [x] ~~**A whole-number field accepted letters.**~~ `TextField(value:format:)`
      lets anything be typed and simply fails to parse it, so "abc" sat in a
      semester field looking like an answer until the form was saved and
      reverted it. `IntegerField` drops everything but ASCII digits as they
      arrive, so there is no invalid state to explain.
- [x] ~~**Return threw away a description.**~~ A sheet's Save is its default
      button, so Return anywhere inside the sheet fired it — and the
      description field's uncommitted text went with it: typing a line,
      pressing Return, and typing another left only the second one, with the
      form still open and looking fine. `axis: .vertical` never changed that;
      it wraps and grows, but the key belongs to the button. The description
      is a `TextEditor` on macOS now (`FormTextEditor`), which is a real text
      view and takes Return itself. §2.4.
- [x] ~~**A list didn't say how many things were in it.**~~ The three
      top-level lists carry the count as a navigation subtitle, following the
      search and the filters rather than the database — the number is only
      useful as an answer to "what am I looking at". §2.4.
- [x] ~~**Cards were tight at the sides.**~~ Content sat 14pt from a card's
      left and right edges, which reads as cramped next to the room above and
      below it. 16pt now, at the sides only, and the rows lost 2pt above and
      below. The grid tiles keep the single measure they always had. *Two
      earlier attempts were reverted: 14pt squared on all four sides, then
      20pt at the sides, which is too much.* §2.5.
- [x] ~~**Section titles stopped sticking.**~~ They stay above their card
      and scroll with it. The pinning restored a few commits earlier is out
      again, and so is the background it needed. §2.5.
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

**Built (2026-08-26).** The app had no `Commands` scene at all — no menu
items beyond the system's, no shortcuts — which on macOS reads as unfinished
however the views look. It has one now: `ScadeCommands`, declared in ScadeUI
so the App target stays a shell that opens a database.

Every shortcut has a menu item. That was the rule §1.4 set and it decided the
shape of the implementation: shortcuts hung on the buttons themselves would
have been a fraction of the work and undiscoverable.

### 1.1 Navigation

| Shortcut | Action | Menu |
|---|---|---|
| `⌘1`–`⌘4` | Home / Educations / Subjects / Grades | Go |
| `⌘ö` | Back | Go |
| `⌘↑` | Open the record this one belongs to | Go |
| `⌃⌘S` | Toggle the sidebar | View |
| `⌘,` | Settings | Scade |

**`⌘ö`, not `⌘[`.** The app is used on a Swiss keyboard, where `[` is `⌥5` —
unreachable as a shortcut — and `ö` sits where a US layout puts `[`, which is
why macOS apps answer `⌘ö` for Back there. SwiftUI matches a key equivalent
by character, not by physical key, so it is bound as `ö` literally: right for
the one machine this app runs on, wrong on a US layout, and deliberate.

**`⌘↑` is Finder's Enclosing Folder**, applied to records: a grade opens its
subject, a subject its education. Taken from GradeMaster, which had
`Ctrl+Shift+A` and `Ctrl+Shift+Q` for the same two jumps.

**No `⌘]`.** A `NavigationStack` keeps no forward history, so there is
nowhere for it to go.

`⌘,` needed a decision rather than an implementation, and **(b) was taken**:
a `Settings` scene on macOS, no sidebar row anywhere. The argument that
settled it is that `⌘,` is not the app's to define — the system routes it to
a `Settings` scene, so an app without one leaves the standard shortcut
answering nothing at all. A sidebar row can't be reached by it, however the
row is labelled.

### 1.2 Records

| Shortcut | Action | Menu |
|---|---|---|
| `⌘N` | New — whatever the screen in front makes | File |
| `⌘E` | Edit this record | File |
| `⌘⌫` | Delete this record, through its usual confirmation | File |
| `⌘F` | Focus the search field | Edit |
| `⌘⇧F` | Clear this screen's filters | Edit |
| `⌘↩` | Save the open form | — |
| `⎋` | Cancel the open form, clear the search | — |

`⌘N` is context-sensitive without anything tracking context: each screen
publishes its own action and the menu item takes that screen's name for it —
"New Subject" on an education, "New Grade" on a subject, greyed on a grade,
which has nothing below it. The same for `⌘⌫`, which reads "Delete
Education…" or "Delete Grade…" and goes through the confirmation the toolbar
button already used.

`⌘↩` came first, ahead of the rest, because the description field needed it:
Return there belongs to the text (§2.4), so the form had lost its keyboard
exit. It is an invisible second button rather than a shortcut on Save
itself — giving Save an explicit `keyboardShortcut` **takes away** the
default-button role `confirmationAction` granted it, and plain `↩` in the
name field then does nothing. Measured, on the first attempt.

**Deliberately not built:**

- **`⌘R` reload.** GradeMaster had four spellings of it (`F5`, `Ctrl+R`,
  `Ctrl+F5`, `Ctrl+X`) because a Blazor page held stale data. Every screen
  here is a live `ValueObservation`; the command could only re-run a query
  that is already correct.
- **`⌘⌫` on a list.** The three lists are card grids with no selection
  model, and the context menu already deletes. Building selection to serve
  one shortcut is a large change for a small gain; scoping the command to
  detail screens gives it an unambiguous target for nothing.
- **`⌘⇧N` for a new education from anywhere.** `⌘2` `⌘N` is two keystrokes.
  The shortcut went to New Window instead.
- **`⌘S`.** `⌘↩` saves, and `⌘S` means "save a document" in an app that has
  no documents.

### 1.3 Windows and tabs

| Shortcut | Action |
|---|---|
| `⌘T` | New tab |
| `⌘⇧N` | New window |

`⌘N` was New Window, from SwiftUI's default `.newItem` group. It is the
app's content key now, the way Notes, Reminders and Things all take it, and
New Window moved beside the `⌘T` that didn't exist.

**Why `⌘T` did nothing before**, in two parts, both needed:

1. **There was no New Tab command.** macOS offers one only when something in
   the responder chain implements `newWindowForTab(_:)`, and SwiftUI's
   `WindowGroup` doesn't. The Window menu already had Show Previous/Next Tab
   and Merge All Windows — tabbing was enabled the whole time; nothing could
   start it.
2. **The system tabbing preference is "In Full Screen Only"**
   (`AppleWindowTabbingMode` unset). So even with the command, a new window
   would not have joined as a tab on the desktop.

`WindowTabbing` handles both without touching a system-wide setting: it notes
the key window, asks SwiftUI to open another, and adds the new one to that
window's tab group as it appears.

**Closing the last window quits the app.** The macOS default is the opposite,
and it is the right default for an app with something left to do without a
window — another document to open, background work, a menu bar item, a sync.
Scade has none of that. It is one database with a window on top, so a
windowless Scade sits in the Dock claiming otherwise, and `⌘Q` becomes a
second thing to do after the one that already meant "done". It also makes the
restore in README honest: that is a file copy *with the app quit*, and closing
the window now closes the database rather than putting it out of sight.

`Window` in place of `WindowGroup` gets this for free, and is the wrong tool —
it terminates on close by forbidding a second window, taking `⌘⇧N` and the
`⌘T` above with it. `ScadeAppDelegate` answers
`applicationShouldTerminateAfterLastWindowClosed` instead, which decides only
what happens after the last window closes and leaves tabbing alone.

### 1.4 Implementation notes

- Declared as a `Commands` scene on `WindowGroup`, in ScadeUI, not in the App
  target.
- **`FocusedValues`, not a shared selection holder** — the earlier sketch
  here proposed "a small observable focus/selection holder in the
  environment". A focused value is better on the app's own terms: it flows
  *up* from whichever screen is in front and disappears with it, so there is
  no state to keep correct and nothing ambient to go stale. The no-ambient-
  state rule from CLAUDE.md applies to UI state too.
- **A `ScreenAction` must not be `Equatable`.** It was, briefly, comparing an
  id the caller passed in. The commands whose id never changed — Edit and
  Delete, whose ids were string constants — silently stopped working:
  SwiftUI read the equal value as no change and kept the *first* action it
  was ever handed for that key, closing over a body pass whose state was long
  gone. The menu item was enabled, correctly named, and did nothing when
  chosen. The ones that did work (`⌘ö`, `⌘↑`) were the ones whose ids
  happened to change.
- **A modifier on the `NavigationStack` does not reach a pushed screen.**
  `goBack` was published from `SectionStack` and Back sat greyed on every
  detail. It goes on `navigable` instead — which is the second time this has
  been paid for; see the note there about `\.navigate`.
- Every shortcut has a menu item. Undiscoverable shortcuts are worse than
  none.

### 1.5 iOS

Full-size keyboard shortcuts also apply to iPad with a hardware keyboard, for
free, because the commands are declared on the shared scene rather than
inside `#if os(macOS)` — only the window and tab commands are macOS-only.
iPhone gets nothing from this section, which is fine.

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

**Settings is not a section on any platform.** On macOS it is a window of its
own, opened from the app menu or with `⌘,` — where every Mac app keeps it, and
where the system looks for it whether or not the app agrees. Everywhere else
it is a toolbar button on Home, opening as a sheet: a tab slot is permanent
real estate and Settings is visited rarely.

*Changed 2026-08-21.* It was a sidebar row on macOS until then, on the reading
that SPEC §4's "Settings in the sidebar" should be honoured where a sidebar
exists. Two things were wrong with that. A fifth permanent slot went to the
screen visited least, and choosing it swapped the whole detail column for a
form — a *modal* errand rendered as a place you navigate to. And `⌘,` cannot
be pointed at a sidebar row: the system binds it to a `Settings` scene, so
the app was leaving the one shortcut every Mac user tries doing nothing.
SPEC §4 is superseded here by the platform convention.

iPad was expected to keep it, on the assumption that `.sidebarAdaptable` would
give iPad a sidebar. **It doesn't.** iPadOS renders a top tab bar, and five
tabs plus its sidebar toggle don't fit an 11-inch portrait window: the bar
paginates, and Settings lands on a second page — present in the accessibility
tree, not reachable by tapping.
`defaultAdaptableTabBarPlacement(.sidebar)` does not override this; it was
tried and had no observable effect. Four tabs fit, so four tabs it is.

**Sidebar rows are the system's, in every respect.** Icon in front of the
word, at the system's row height. Three arrangements were rendered and
compared (2026-08-21): stacked icon-over-label reads as an iPad app that got
resized — stacking is the *tab bar* idiom, and a sidebar is a list, which is
why Finder, Mail, Notes, Music and Reminders all run the icon leading. Rows
6pt taller than standard were tried too and look unbalanced: four larger
rows in a sidebar that stays narrow draw attention to their own size.

The empty space under four rows is not a problem to solve. A sidebar is a
list of places, and every Mac app with few sections leaves the rest of the
column empty.

**The window's title is the section's name, with nothing in front of it.**
"Scade – Educations" was built and reverted the same day. Two reasons, and
the second is the one that matters: an app switcher shows the icon, so
whose window it is was never the unanswered question; and on macOS the
window's title *is* the toolbar's — `navigationTitle` sets both and no API
separates them — so the prefix appeared twice on screen to answer it. A
detail screen would have read "Scade – Informatiker EFZ" above a card
saying *Informatiker EFZ* in bold.

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
- `⌘1`–`⌘4` in §1.1 now map to tab selection rather than sidebar selection.
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

**A list says how many things are in it.** The three top-level lists carry
the count as a navigation subtitle — "13 items" under "Grades". It follows
the search field and the filter menus rather than the database, because the
number is only useful as an answer to *what am I looking at*; a total that
ignores the filter answers a question nobody asked. Nothing is claimed before
the first snapshot arrives (§2.7).

**"items", not the record's own name.** The title above it already says what
they are, and macOS joins title and subtitle wherever it lists a window — the
Window menu, the app switcher, Mission Control — so "13 grades" read "Grades
– 13 grades" there. The bare number was the other candidate and loses out
away from the window, where "Grades – 13" could be a version or a filter.

**A form's free text reads from the left, its numbers from the right.**
macOS's grouped `Form` right-aligns a labelled field's content, which is
correct for a figure and wrong for a name — and on a name it hides a typed
space entirely (§0.1). Free text gets a label column and leading alignment
(`FormTextField`); numbers keep `LabeledContent` and the trailing edge, which
is the whole point of a column of figures.

**A field that takes a whole number takes nothing else.** Not "accepts and
then rejects": `IntegerField` drops everything but ASCII digits as they
arrive, so the field never holds a value the form will later refuse.

**A description is a paragraph, and Return starts a new one**, and `⌘↩`
saves from inside it (§1.2). Everywhere else in a sheet Return means Save — but a field written to hold 2500
characters has to take the key itself, or it hands the text to the default
button and loses it (§0.1). On macOS that means a `TextEditor`, which costs
the field its growth: it stands four lines tall and scrolls inside instead of
pushing Save off the bottom of the sheet. iPhone keeps the wrapping
`TextField`, where a software keyboard's Return already inserts a line break.


Each list row currently gives near-equal weight to every field. Decide, per
entity, what the eye should land on first:

- Education row: name dominant; institution and date range secondary;
  average as the trailing anchor.
- Subject row: name + semester dominant; parent education secondary; average
  trailing.
- Grade row: value dominant (it's the point of the row); date and
  description secondary; weight tertiary. **On the grade *tile* the value
  takes the trailing anchor instead of leading** (amended 2026-08-20). The
  three grids share one grammar — what the record is on the left, its number
  on the right — and a value that led would be the only number in the app
  that didn't sit where the eye has learnt to find it. Dominance is carried
  instead by being the sole number on the tile and the only field that turns
  red. The one case where it still leads is the case §2.4 was written for:
  a grade with nothing to name it, under its own subject and saved without a
  description, where the value really is all there is.

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

**A detail screen is not a table of its fields** (added 2026-08-21, building
the education detail). It was eight `LabeledContent` rows — Average,
Institution, Starts, Ends, Semesters, Subjects, Grades, Status — every one the
same size, with a hairline between each. That is GradeMaster's detail screen
reproduced rather than improved on, and §2.5's complaint exactly.

Those were never eight facts worth eight rows; they are one paragraph of
identity. The rule that replaces them:

- **Drop the label wherever the value says what it is.** An institution reads
  as an institution, a date range as a date range, "8 semesters" as a count.
  A label earns its place only where the value alone is ambiguous — and if
  every value on a screen needs one, the screen is a form, not a detail.
- **Then apply the ladder to what's left.** The average takes
  `headlineNumber`, the name sits beside it at `.title2`, the institution and
  dates step down to `rowSecondary`, and the counts to `rowMeta`. Eight rows
  become four lines and one card.
- **A detail screen is where the whole value lives.** The tiles bound their
  growable fields because a grid row is as tall as its tallest member; a
  detail card has no neighbour to drag, so the bounds don't carry over. The
  institution wraps here, and the date range wraps rather than truncating —
  "Aug 1, 2023 – Jul…" is not a date range, and the half that goes is the
  half the screen was opened for. Copying the tiles' `.lineLimit`s across is
  the mistake to avoid.
- **The badge stays in the phrase.** The tiles pin completion status to the
  trailing edge and are right to: a tile is 300pt across. A detail card is as
  wide as the window, and the same pin leaves a word at each end with a void
  between them — which is the rule in §2.5 about only the number going hard
  right, in the case that shows why it exists.

**What heads a detail card is the field the record cannot be without.** An
education and a subject have a name, so that is the heading and the
navigation title repeats it. A grade has neither a name nor a required
description, so its card is headed by the **date** — the one field every
grade has, which cannot grow and cannot be missing, and which the row under a
subject leads with too, so the record reads the same way in both places. Its
navigation title is the more specific thing where there is one: the
description, or failing that the date. It read "Grade" on every grade in the
app.

**Only what the screen is about.** The grade detail listed its subject's
completion state and its education's institution — nine labelled rows across
three sections, most of them facts about *other* records, each one press away
on the record that owns it. A detail screen shows what the record is and
links to the rest.

**The parent record's own name is repeated from the navigation title, on
purpose.** macOS draws that title small and in chrome, where it reads as the
window's label rather than the record's, and the institution and dates below
need something to hang from.

**How much of a description to show, and what to show when there is none**
(decided 2026-08-21). A grade's description is optional and runs to 2500
characters, so every place it appears needs an answer:

- **One line wherever it appears in a list or a grid**, tail-truncated, with
  a tooltip carrying the rest. One and not two, which is what the education
  and subject tiles give their *names*: a name identifies a record and has to
  be read whole, a description is a note. It also keeps every grade tile the
  same height, which a grid wants.
- **Full on the grade's own screen**, in a card of its own, selectable —
  the same treatment the education and subject descriptions get.
- **Nothing at all where there is none.** Not a hyphen, not an en-dash. That
  is the old app's `Label: value` table idiom, where every cell has to be
  filled; once the labels are gone (above) there is no cell, and a column of
  dashes is louder than the nothing it reports. Rows are one line or two, and
  varying row height is ordinary — a column of placeholders is not.
- **Which means the row must not be built around it.** Under one subject the
  date leads and the description hangs beneath as the note; on the grades
  list, where the question is *which grade is this*, the description heads
  the tile and falls back to the subject name. Heading both with the optional
  field is what made a column of grades ragged — the date landed on the first
  line for some rows and the second for others.

**A number keeps its edge whether or not the row has a name.** A grade under
its subject often has no description to head it, and the value used to take
the leading edge in that case — which reads well on a tile standing alone and
badly the moment those rows are stacked in a column: some values hard left,
some hard right, and no column to run the eye down. The value drops onto the
date line instead, still at the trailing edge, and the row is one line rather
than one line and an empty one. This is `.monospacedDigit()`'s argument again:
what a column of numbers is *for* is comparing them without reading them.

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

  **A detail screen is a document, and stops being a `List` altogether**
  (decided 2026-08-21, building the education detail). A detail screen has
  nothing to swipe, nothing to select and nothing to reorder. It is a
  `ScrollView` of cards, drawn by `DetailSection` and `DetailCardRow` from the
  same `CardRowSurface` the `List` rows use, so there is one card in the app
  and not two that nearly match.

  **Home followed, later the same day — and there it was a bug fix.** Home was
  the one screen keeping a `List` on macOS, because its quick-add is a swipe
  on iPhone and `.swipeActions` is `List`-only. That reason holds *on iPhone*,
  and it bought nothing on a Mac, where the same `List` was clipping every row
  it drew (§0.1). So Home forks: a `List` on iOS for its swipes, the same
  `ScrollView` of cards as everywhere else on macOS. **Nothing in the app is a
  `List` on macOS now except the sidebar**, which is one — `List(selection:)`
  is how a `NavigationSplitView` learns its detail column should change.

  **Each card carries its own margins**, rather than the stack padding them
  all — which keeps the margin in one place whether a card is first, last or
  alone.

  *Sticky headers were built and then removed.* What they cost, recorded in
  case they ever come back: pinning is a `LazyVStack` feature, and **a lazy
  stack pins only a `Section` it can see** — one wrapped inside a custom
  `View` is invisible to it and silently doesn't pin, which is how the first
  attempt looked finished and did nothing.

  **A card's sides are padded a little more than its top and bottom, on
  purpose.** 16pt at the sides; 10 above and 12 below a block of text, 8
  above and below a row. The block of text is short at the top on purpose:
  a card's first line is the biggest type on it, and a large font carries
  slack above its cap height — 14pt all round measured 18 above the title
  against 14 below the last line. A card is far wider than it is tall, so the same measure
  on all four sides doesn't *look* the same — but the difference is a touch,
  not a step: equal-at-14 and 20-at-the-sides were both tried and both
  reverted. The internal divider is inset to match the content, so the line
  starts and ends where the text does. Grid tiles are the exception and keep
  one measure all round.

  **A card's title sits above it and stays there.** "Semester 4" over the
  dashboard's cards, "Description" and "Subjects" over the detail screens'.
  **Nothing pins.** Sticky headers were built here and taken back out: a
  title that outlives the card it names has to paint an opaque background to
  stay legible, and that background draws a band across the rows passing
  under it. Without pinning the title needs no background at all, which is
  the version that looks like a heading rather than a stripe.

  Three things follow, and the third is what forced it:

  - The window margin moves back to where it belongs. `groupedListStyle`
    exists to work around a `List` refusing `contentMargins`; a `ScrollView`
    takes padding on its content and keeps its scroller on the window edge.
  - The pressed-fill bug cannot occur, because there is no row presentation
    to inherit — the same reason the grids escaped it.
  - **A macOS `List` swallows the drag that selects text.** Every `Text` in
    one is inert however `.textSelection(.enabled)` is applied — on the
    `Text`, on the row, and on the list itself; all three were tried and
    measured, and a `contentShape` on the row was ruled out as the cause
    first. A detail screen is exactly where selecting text matters: an
    institution's full name, a date, an average, a description worth pasting
    elsewhere. **The identity card and the description are selectable; the
    subject rows are not** — a row is a link, and a drag that selects text is
    a drag that doesn't open anything.

  **A detail screen's sub-list is the first kind, and the grids don't reach
  it** (decided 2026-08-21). All three top-level screens are grids now, so
  the education detail's subject list is the one place the distinction still
  gets made — and it goes the other way. A top-level screen is a collection
  you arrive at to pick from; a detail screen's list is one record's
  contents, read down a column while the header above it stays in view. The
  averages line up in one column, which is what the second §2.5 question
  asks for, and tiles here would push the header off screen to say less.
- **A row is capped in width; a tile is not.** Past about 900pt a row stops
  being read as one thing: the name is at one end of the screen and its
  average at the other, with nothing in between. *Subjects, the screen that
  first needed this, became a grid instead and the plumbing was removed with
  it rather than left inert — with the note that the next long list to stay a
  list would meet the same wall. **The education detail is that screen**
  (2026-08-21): its subjects are a card of rows, and at a wide window the
  averages sit an inch and a half from the names they belong to. Left
  uncapped for now, deliberately — the same shape is on Home, which is
  already approved as it stands, so capping one screen and not the other
  trades a spacing flaw for an inconsistency. Decide it across both.*
- **A grid is capped in width too — 1400pt** (decided 2026-08-27). Not the
  same wall as the row above it: a tile past three columns is held by
  `maximumCardColumns`, so what a very wide window stretches is the tiles
  themselves, until a grade tile is a name at one end and a number at the
  other — the row problem arriving by another road. `cardGridMaximumWidth`
  is set from the machine the app runs on: a 14" MacBook Pro offers about
  1362pt of content at full width, so the cap sits just above that and never
  takes effect there. On a 27" display the content centres and the tiles stay
  the width they are on the laptop. The scroll view stays full width, so the
  scroller stays on the window edge; only its content is capped.

  **Home and the detail screens are deliberately left uncapped**, which
  settles the question above by splitting it rather than answering it across
  both. They read as documents down a single column, they are approved as
  they stand, and the "decide it across both" worry was that capping one
  screen and not another trades a flaw for an inconsistency — but a grid and
  a document are not the same shape, and the grids are where the stretching
  actually hurts. The row-width finding stands unfixed on Home and on the
  education detail.
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

  Educations answer "no" and "no" — a few objects you pick between. That the
  old app used cards everywhere is not evidence either way: it used cards for
  everything, which is a template applied uniformly rather than a decision
  made per screen, and CLAUDE.md limits that reference to content and
  priority, "never for density or layout".

  **Subjects answer "yes" and "yes", and use the grid anyway** (decided
  2026-08-11, on preference, after seeing both built). Recorded as an
  override rather than rewritten into a rule the outcome would fit, because
  the reasoning still stands and the cost is real: with dozens of subjects the
  averages no longer form one column, and finding the low one means reading
  rather than glancing. Two things make the cost smaller than it first looks —
  a uniform grid still aligns the tiles' top-right corners, so three columns
  give three average sub-columns rather than none; and the semester filter
  usually narrows the screen to a handful, which is the regime where the
  scanning argument never bites anyway.

  **Grades were not settled by that, and got the grid too** (decided
  2026-08-20, on preference, after the subjects grid was seen working). The
  two questions answer "yes" and "yes" here more emphatically than anywhere
  else in the app — hundreds of records whose value *is* the record — so this
  is a second override, taken on its own screen rather than inherited from
  the first. What that buys and what it costs:

  - **The cost is real and larger than on subjects.** With hundreds of
    grades, no filter that narrows the screen to a handful the way the
    semester filter narrows subjects, and the value as the whole point of the
    record, this is precisely the case the scanning argument describes. Three
    average sub-columns instead of one is a weaker consolation at three
    hundred records than at thirty.
  - **What it buys is separation, which grades needed more than the other
    two.** A grade is the only record with no name — the §0.1 finding was
    that the list read as one undifferentiated run — and a run of unnamed
    rows is where a card earns the most. A tile makes each grade a thing;
    rows made them a page of numbers.
  - **It is not a substitute for date sections.** Those remain the better
    answer to the same finding and remain blocked on a sort order (§0.1,
    [SPEC-BACKLOG](SPEC-BACKLOG.md) §4). A grid and sections are compatible —
    `LazyVGrid` takes `Section` — so this doesn't foreclose them.

  **A grade tile is headed by the most specific thing that names it.** The
  other two records have a name field; a grade has an optional description,
  and plenty are saved without one. So the heading is the description, or
  failing that the subject — which then drops off the context line, so
  neither parent is ever printed twice. Under a subject, where the screen
  already says which subject it is, an undescribed grade has nothing to head
  it and the value leads instead of anchoring the right of an empty line.

  **Two unbounded fields on one line share the squeeze; they don't take
  turns.** The education tile could pin its years with `.fixedSize()` because
  four digits are four digits. A grade's context line is a subject name
  beside an education name, both capped at 255 characters, and giving either
  priority let it crowd the other out — the separator `Text` between them
  wrapped, and a long subject name made the tile a line taller with both
  names correctly held to one line each. The bound belongs on the line, not
  on the fields in it.

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

**Nothing at all, while there is nothing to say.** Every screen observes its
data, so every screen is on screen for a frame with empty arrays in it — and
an empty state that reads those as "there is nothing here" flashes a false
answer on every section switch. The empty states wait for the first snapshot
(`hasLoaded`) rather than being animated in more gently; the fix for a wrong
frame is not to fade it.

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

**No `.pointerStyle(.link)` — except where something really is a link.** The
pointing hand is a *web* convention that macOS reserves for navigation leaving
the app. Using it for an in-app push promises a browser. Internal navigation
keeps the arrow — the background change is the whole affordance.
Accent-coloured or underlined text is out for the same reason: that's what a
link looks like, and none of these are links.

The two in Settings ▸ About are. They open GitHub in a browser, so they take
the hand, and the accent colour with it — the same convention, read the right
way round. That is the whole of the exception: a control that leaves the app.

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

**Every icon-only control carries a help tag.** A toolbar of glyphs is only
legible if resting on one says what it does, so each has a `.help` — and it
says what the *click* does rather than repeating the label: "Add a subject to
this education", not "New Subject". A toggle names the state it is about to
move to ("Show only grades below 4"), because a toggle's ambiguity is always
which way it is going. Where a button is disabled, the tag is the reason it is
disabled, which is the one thing the greyed-out glyph cannot say.

**A grade chip's tag is its date, and a dashboard subject's is its weight.**
The chip has room for the value and the weight and nothing else, so the date
— the one field every grade has — was otherwise only readable by opening the
grade. The subject beside it is the same problem one level up: the dashboard
row carries the name, the grades and the average, and never says how much the
subject counts for in the education above it. Both are facts the row has no
width for and the eye has no other way to reach.

**Attach a help tag to the control, not to a wrapper around it.** The
dashboard's subject name is a `DetailButton`, and a `.help` at the call site
never reached it; the tag is a parameter the button applies to itself.
`DetailButton` is the one control here composed from another view, so it is
the only one that needed saying.

**Verify a help tag by reading `AXHelp`, not by watching for the bubble.**
Every tag in the app is on a button, and `System Events` will read the
attribute back — `help of <element>`. The bubble itself does not reliably
draw for a pointer moved by `CGEvent`, which cost an afternoon and produced
one confident wrong conclusion about modifier order before the attribute was
checked instead.

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
