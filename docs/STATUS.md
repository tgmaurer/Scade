# Status — 2026-08-27

**This is not an amendment to SPEC.md.** SPEC.md still describes what Scade
is meant to become, and every open item in SPEC-BACKLOG is still open. This
records something different: the point at which the app does everything its
author needs, and active development stops.

The project may be picked up again. Nothing here is a decision that it
won't be — it is a note of where the work was put down, and why, so that
whoever reads it next (including its author, later) doesn't have to
reconstruct it.

## Done

**The macOS app.** SPEC §§1–4 are built and in daily use: educations,
subjects and grades with weighted averages up the hierarchy, search, filters,
validation, a dashboard, three list screens and three detail screens. The
visual pass in SPEC-POLISH §2 is complete except for the one open item noted
below, and §1's menu bar and keyboard shortcuts are built.

## Frozen

**iPhone and iPad.** They build, they run, and they stop there. The shell
forks per platform and the screens are shared, so nothing rots quietly — the
iOS target still has to compile — but no design decision is taken for either
any more. The app is used on one Mac.

**iCloud sync (SPEC §5).** Not built, and not attempted. Two reasons, in
order: there is no second device to sync *to*, and the app's own iCloud
container needs a paid Apple Developer Program membership, which is not
being bought for an app that isn't being published. The design notes in
SPEC §5 stay as they are — they were right about how to do it, and would be
the starting point if a second device ever appears.

**Publishing.** No release build for anyone else, no notarisation, no App
Store. The app is built from source on the machine it runs on. README
explains that; it is why Gatekeeper is satisfied there and would not be
anywhere else.

## What replaced iCloud sync

Backups, written where you tell them to go. **Settings → Backup** takes a
folder once — iCloud Drive is the sensible answer, since a backup that lives
only on this Mac dies with it — and **Back Up Now** writes a dated folder
into it holding:

- `scade.sqlite`, a consistent `VACUUM INTO` snapshot: the file that
  restores the app
- `overview.csv`: everything on one sheet, one row per grade with its
  subject and education spelled out, so a spreadsheet needs no join. A left
  join, so a subject with no grades and an education with no subjects each
  keep a row
- `educations.csv`, `subjects.csv`, `grades.csv`: the same data in a form a
  script can read, ids intact so the three re-join

Restoring is a file copy with the app quit, documented in the README. There
is no Import button, and that is deliberate: an importer has to answer what
happens to ids that already exist, to records edited on both sides, to a
half-applied merge — questions worth answering for a shared app and not for
one user with one Mac and one database.

The folder is remembered as a security-scoped bookmark rather than a path,
because a sandboxed app cannot open a folder it was not handed.

## Changed for this milestone

- `ENABLE_USER_SELECTED_FILES` went from `readonly` to `readwrite` — the
  backup folder is the only thing it enables.
- The entitlements file is now empty. It declared CloudKit and push
  notifications with no iCloud container behind either: leftovers from the
  §5 plan, and the two things that would have needed a paid membership.
- `PreviewData` is no longer `#if DEBUG`. Nothing to do with the milestone
  except that it was found by it: a Release build had never been attempted,
  and it failed with 57 errors, because a `#Preview` body compiles in
  Release too and 52 of them are not guarded. See the note on the type.
- The sandbox stays on. Turning it off would move the database to a
  different path and the app would open empty until the file was moved by
  hand.

## Still open, if work resumes

- **The row-width problem on Home and the detail screens.** The three grid
  lists were capped at 1400pt on 2026-08-27; Home and the details were left
  full width deliberately, so a card as wide as the window there still puts a
  subject's name at one end and its average at the other. SPEC-POLISH §2.5.
- **SPEC-BACKLOG** in full — linked semester counts, education completion
  cascading to subjects, sectioned lists, and the rest.
- **The iOS layouts**, which are functional and unconsidered.
