# Scade — Design Assets

Visual input for [SPEC-POLISH.md](../SPEC-POLISH.md) §2. Everything here is a
*picture*, not a decision: these folders hold what the UI should look like, and
SPEC-POLISH holds what that means in terms of work.

Nothing here is code, and nothing here is authoritative about behaviour. If an
image implies a rule that SPEC.md doesn't have — a new field, a different sort
order, a validation that doesn't exist — that's a [SPEC-BACKLOG.md](../SPEC-BACKLOG.md)
item, not something to build because a mockup showed it.

## Where things go

| Folder | Holds | Authority |
|---|---|---|
| [`mockups/`](mockups/) | intended Scade UI, made or commissioned for this app | **Target.** Build toward these. |
| [`reference/grademaster/`](reference/grademaster/) | screenshots of the old MAUI app | Starting point, not a target. What a screen needs to say — never how it looked. Assume flaws. |
| [`reference/inspiration/`](reference/inspiration/) | screenshots of other apps | Ideas. Never copy directly. |

Only `mockups/` is something to match. Both `reference/` folders are prior art:
they show what has been tried, which is useful precisely because some of it was
tried badly. Improving on a reference is the expected outcome; reproducing one
is not.

Each folder has its own README with what belongs in it and what doesn't.

## Naming

Filenames are the only metadata that survives, so they carry the context:

```
<platform>-<screen>[-<state>].<ext>
```

- **platform** — `macos`, `ios`, `ipados`
- **screen** — the SPEC §4 screen: `home`, `educations`, `education-detail`,
  `education-form`, `subjects`, `subject-detail`, `subject-form`, `grades`,
  `grade-form`, `settings`
- **state** *(optional)* — `empty`, `error`, `filtered`, `dark`, `wide`,
  `compact`, `dynamic-type`

Examples:

```
macos-home.png
macos-home-wide.png
ios-education-form-error.png
ios-educations-empty-dark.png
```

If a file covers several screens at once, name it for what it's demonstrating
(`macos-row-hierarchy.png`) rather than inventing a compound screen name.

## Format

- **PNG** for anything with UI text — screenshots and exported mockups.
- **PDF or SVG** for vector work, if the source is vector.
- **2x** or better on screenshots. A downscaled screenshot loses exactly the
  detail worth looking at (weights, badges, secondary labels).
- Keep files reasonably sized. These are committed to git, which has no
  concept of superseding an image — every revision stays in history forever.
  Replace a file at the same path rather than adding `-v2`, `-final`,
  `-final-2`.

## Using these

When picking up a §2 task, read the relevant image *and* the SPEC-POLISH
section it belongs to. The image shows the destination; SPEC-POLISH records
the constraints that still apply on the way there — chiefly that polish work
changes presentation and interaction only.

Two constraints that a mockup cannot override, because they're accessibility
requirements rather than taste:

- Failing-red stays distinguishable from the accent colour in both
  appearances, and keeps its non-colour fallback (`GradeValueLabel` already
  handles Differentiate Without Color — don't regress it).
- Every screen has to survive the largest Dynamic Type sizes. A mockup drawn
  at the default size is not evidence that a layout works.
