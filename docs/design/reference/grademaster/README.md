# GradeMaster — Visual Reference

Screenshots of the old MAUI app. Empty until they're added.

GradeMaster is the app Scade replaces. It was used in earnest, which makes its
screens evidence of what information a user actually needs in front of them —
and that is worth mining even though the rewrite exists to leave the old app
behind.

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

## Worth capturing

If screenshots are being taken deliberately rather than found, these are the
ones that answer questions Scade still has open:

- The dashboard / home equivalent, with real data in it. SPEC-POLISH §2.3
  calls Home the screen most worth designing, and it's the one with the least
  precedent.
- A grade list dense with entries — the row-hierarchy question in §2.2 is
  really a question about what a *full* list looks like.
- Any screen showing an average alongside the grades that produced it.
- Whatever the app did about semesters and filtering.
- Its empty states, if it had any.
