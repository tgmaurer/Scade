# Mockups

The intended look of Scade. **This is the target** — when a mockup here and the
current UI disagree, the mockup wins, subject to the constraints in
[../README.md](../README.md).

**Empty on purpose, and likely to stay that way.** Drawing mockups for this app
was judged more work than it's worth, so the visual direction is written out
instead, in [SPEC-POLISH.md](../../SPEC-POLISH.md) §2.2–§2.5 — shell and
navigation, Home, the type ladder, surfaces and separators. Treat those
sections as this folder's contents.

The folder stays because a written spec is bad at exactly one thing: settling
what something *looks* like when words have run out. If that happens — most
likely for the app icon and accent colour in §2.1 — an image belongs here and
outranks the prose.

## What belongs here

- Screen designs for any SPEC §4 screen, on any platform.
- Component studies: a row treatment, a badge, an empty state, a form.
- Colour and type explorations — including the accent colour decision that
  [SPEC-POLISH.md](../../SPEC-POLISH.md) §2.1 calls the highest-leverage change
  in the whole phase.
- App icon drafts.

## What doesn't

- Screenshots of the app as it currently is. Those aren't a target; if one is
  needed to show what's wrong, put it next to the mockup that fixes it and say
  so in the filename (`macos-home-current.png` beside `macos-home.png`).
- Other people's apps — those go in [`../reference/inspiration/`](../reference/inspiration/).

## Naming

Per [../README.md](../README.md): `<platform>-<screen>[-<state>].png`, e.g.
`macos-home.png`, `ios-education-form-error.png`.

Partial coverage is fine and expected. One well-resolved screen is more useful
than ten half-drawn ones — the accent colour, row hierarchy, and badge
treatment established on a single screen carry to the rest.

## Annotations

If a mockup needs explanation — spacing values, which element is dominant, why
a control moved — a sibling `.md` file with the same basename is the place for
it (`macos-home.md` next to `macos-home.png`). Text in a repo is greppable and
diffable; text baked into an image isn't.
