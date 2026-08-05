# GradeMaster — Visual Reference

Screenshots of the old MAUI app: home, all three list screens, all three
detail screens (wide and narrow), all three edit forms, settings, and the
hover/menu states from home.

GradeMaster is the app Scade replaces. It was used in earnest, which makes its
screens evidence of what information a user actually needs in front of them —
and that is worth mining even though the rewrite exists to leave the old app
behind.

## A starting point, not a target

**Nothing here is to be matched 1:1.** GradeMaster is a solid reference for
what's *possible* and what the domain needs on screen. It is not a standard to
meet. Assume, going in, that any given screen contains:

- layout that grew by accretion rather than by decision,
- spacing, type and colour that were never deliberately set,
- deviations from Apple's platform conventions — it was a MAUI app, so its
  idioms are cross-platform-generic at best,
- controls chosen for what the framework made easy rather than what the task
  wanted.

So the question to ask of one of these screenshots is never "how do I
reproduce this?" It's **"what is this screen trying to tell the user, and
what's the best way to do that on macOS and iOS?"** Often the answer keeps the
information and throws away the arrangement entirely.

Where [SPEC-POLISH.md](../../../SPEC-POLISH.md) §2 disagrees with a screenshot
here, SPEC-POLISH wins without argument — it's a decision, the screenshot is a
historical artefact. Same for anything in [`../../mockups/`](../../mockups/),
if a mockup ever lands there.

Treat an observed flaw as a finding, not a nuisance: if the old app made
something awkward and Scade shouldn't repeat it, that's worth a line in
[SPEC-POLISH.md](../../../SPEC-POLISH.md) §2 or an item in
[SPEC-BACKLOG.md](../../../SPEC-BACKLOG.md), depending on whether fixing it
changes behaviour.

## Desktop first — mobile only with care

**These are desktop screens.** GradeMaster was designed for a pointer, a
keyboard and a wide window, and that assumption is baked into every layout
decision visible in a screenshot. For Scade's macOS side it's a fair
reference. For iPhone it mostly isn't, and for iPad it depends on the screen.

What travels to mobile:

- **What information a screen needs** — the domain doesn't change with the
  window. This is the main thing worth taking anyway.
- **Grouping and priority** — which fields belong together, what a user looks
  at first.

What doesn't, and must be re-decided per platform:

- **Density.** A desktop row can carry four or five fields comfortably.
  The same row on an iPhone is unreadable. Expect to cut, stack, or move
  fields into a detail view — SPEC-POLISH §2.3 settles this for Home, §2.6 for the rest.
- **Multi-column and side-by-side layouts.** Anything relying on horizontal
  room has no mobile equivalent; it becomes navigation, not layout.
- **Anything assuming hover, right-click, or a resizable window.** Touch has
  no hover state, and swipe actions are the iOS answer to a context menu.
- **Table-shaped screens.** A desktop table becomes a list of rows on mobile,
  and which columns survive as row content is a genuine design question, not
  a translation.

So: reach for a GradeMaster screenshot when working on macOS, and treat it as
a loose hint on iPhone and iPad. If a mobile layout looks awkward and the only
justification is "that's how the old app arranged it", the justification is
wrong — that arrangement was solving a different problem on a different
screen.

## The line

The project [CLAUDE.md](../../../../CLAUDE.md) rule stands and is deliberately
narrow. Restated for this folder:

**Borrowable — what the UI says**

- What information appears on a screen, and what's left off.
- Grouping: which fields belong together, what's primary and what's secondary.
- Information density — how much fits on one row before it stops being
  readable.
- Wording of labels, and of anything domain-specific that was already
  well-phrased in German or English.
- Workflow order: what a user does first, and what the app made easy.

**Not borrowable — how the UI was built**

- Project structure, layer names, file organisation.
- MVVM plumbing, view-model patterns, any ORM-style change tracking. The
  no-ambient-state rule in CLAUDE.md is not negotiable by screenshot.
- Xamarin/MAUI control idioms and their SwiftUI transliterations. A picker
  that looked right in MAUI is not evidence about what belongs on macOS or
  iOS.
- Its visual style as such. GradeMaster is a *content* reference, not an
  aesthetic one — Scade should look like a native Apple-platform app, which
  GradeMaster did not.

The short version: take **what it shows**, not **how it looks** and not **how
it was written**.

## Naming

Prefix everything with `gm-`, then the screen as GradeMaster called it:

```
gm-<screen>[-<state>].png
```

Examples: `gm-dashboard.png`, `gm-education-list.png`,
`gm-grade-entry-error.png`.

The prefix matters — without it these get mistaken for Scade screenshots at a
glance in a file listing, which is exactly the confusion this folder is one
directory away from causing.

Desktop is assumed, so it isn't in the name. If a *mobile* GradeMaster screen
does exist, say so explicitly — `gm-mobile-grade-entry.png` — because it's the
rarer and more directly useful case, and an unmarked file will be read as a
desktop screen and discounted accordingly on iPhone work.

## What the current set already answered

Read as evidence, these are the conclusions drawn in SPEC-POLISH §2 — recorded
here so the next reader doesn't have to re-derive them from the images:

- **`gm-home.png`** — a flat table of `Subject | Grades | Average`, sorted by
  semester but with no semester structure; the semester is welded into the row
  name (`English - 4`). The information is right and the grouping is missing.
  Hence the semester sections in §2.3.
- **`gm-subject_detail.png`** — a hairline between every label and value, and
  every block wrapped in an outlined panel. This is the "too many horizontal
  lines" problem in its purest form, and the reason §2.5 specifies *filled*
  cards rather than bordered ones.
- **The detail screens generally** repeat context the screen already
  establishes (each grade card restating its education and subject) and put
  Back inside the content rather than the navigation bar. Neither travels.
- **`gm-*-narrow_window.png`** — the closest thing here to a compact layout,
  and still a desktop window. Not a substitute for an iPhone reference.

Still unanswered by any screenshot: empty states, and anything at all about
iPhone.
