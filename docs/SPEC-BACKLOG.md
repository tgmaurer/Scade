# Scade — Backlog

Functional changes wanted after v1: new behaviour, new rules, new data.

Three documents, three jobs:

| | |
|---|---|
| [SPEC.md](SPEC.md) | the v1 functional contract — what the app does |
| [SPEC-POLISH.md](SPEC-POLISH.md) | how it looks and feels; presentation and interaction only |
| **SPEC-BACKLOG.md** | behaviour that isn't built and isn't v1 |

Alongside them, [design/](design/README.md) holds mockups and visual
references. Those are pictures, not decisions — a mockup showing behaviour
SPEC.md doesn't have belongs *here*, as an item, not in the build.

The split matters because SPEC-POLISH commits to changing no formula,
validation rule, sort order or schema column. Anything that *does* belongs
here instead, so neither document has to be read with exceptions in mind.

Nothing here is scheduled. An item earns its way into SPEC.md when it's
decided on, and only then gets built.

---

## 1. Linked semester count and date range

**Wanted:** editing an education's date range adjusts its semester count, and
editing the semester count adjusts the end date — so the two stay consistent
without being typed twice.

Today they're independent. The form defaults to the school year (1 August –
31 July) and 2 semesters, and nothing keeps them in step: stretching an
education to three years leaves it claiming 2 semesters until the user
notices.

Open questions, all of which change the feel of the form:

- **Which side wins?** Two-way binding between fields is where forms get
  unpredictable — a user edits a date, the semester count moves, which moves
  the date back. A one-way rule (dates derive semesters, never the reverse)
  is duller and safer.
- **When does it fire?** On every keystroke, or on commit? Recalculating
  mid-edit means a half-typed year briefly implies an absurd count.
- **Does it ever overwrite a deliberate value?** If someone sets 5 semesters
  on a 2-year education on purpose, a later date tweak must not silently
  "correct" it. This probably means tracking whether the field was touched,
  which is state the form doesn't currently keep.
- **What's the conversion?** 2 semesters per academic year is the obvious
  default, but trimester and quarter systems exist, and §1 of SPEC.md rules
  out multi-scale support without saying anything about term structure.

Worth noting the interaction with §3.4: semester is validated against the
education's count, so changing the count automatically can invalidate
existing subjects. That needs an answer before this is built — silently
orphaning a subject's semester would be worse than the inconsistency it
fixes.

## 2. Starting an education that hasn't begun yet

The create form defaults to the school year containing today, which is right
for the common case — logging an education already in progress — and wrong
for planning one that starts next autumn. That user has to retype both dates.

A "next year" affordance would fix it, but it's unclear what shape: a segmented
control on the form, a second menu item next to New Education, or nothing at
all if planning ahead turns out to be rare. Not worth designing until someone
actually wants it.

## 3. Completing an education, and what that means for its subjects

**Wanted:** completing an education stops meaning nothing for the subjects
inside it. Today the two flags are independent, so an education can be marked
completed while its subjects are still in progress — and those subjects keep
offering quick-add, which reads as a contradiction on the dashboard.

Three shapes have been considered, and the one that looks most obvious is the
one to be most careful with:

- **Cascade: completing an education completes its subjects.** Rejected on
  sight by the person who'd use it, and worth writing down why so it doesn't
  come back: it destroys information. "Finished", "abandoned" and "still
  open when the course ended" are different facts about a subject, and a
  single toggle would flatten all three into the first. It is also a bulk
  write with no undo (SPEC-POLISH §4), fired by a control that doesn't look
  like it writes anything but one row.
- **Invert it: an education can only be completed once no subject is in
  progress.** Keeps the data honest and needs no cascade. The risk is that it
  blocks a true statement — a course really can be over with one subject never
  finished — and a rule that can't express reality gets worked around by
  marking subjects completed that weren't.
- **Warn rather than block.** Completing an education with subjects still open
  asks, naming them, and offers to complete them too. Slower, but it's the
  only one of the three that lets the user say what actually happened.

**Also raised:** whether an education whose end date is still in the future
should warn on completion. Probably yes, and probably the same dialog rather
than a second rule — finishing early is legitimate, being surprised by it
isn't.

**Open questions:**

- Does the same argument apply one level down, between a subject and its
  grades? A subject has no equivalent of "unfinished children", so probably
  not, but the rule should be stated for one level or both, not left implied.
- If warn-and-confirm wins, does declining leave the education in progress, or
  complete it and leave the subjects alone? The second is what the words say;
  the first is what a cautious dialog usually does.
- What does the dashboard show for a completed education with an in-progress
  subject, whichever rule lands? That state exists in the data today and has
  no design.

Not scheduled. It's a validation rule either way, which is why it isn't in
SPEC-POLISH: that document commits to changing none.

## 4. Sections on the top-level lists, and the sort order they'd need

Raised while restyling the subjects list (2026-08-11), and the first thing
anyone will suggest looking at that screen: Home groups subjects into semester
sections and it reads far better than a flat run, so why doesn't the subjects
list?

**Because it's sorted differently, and the difference is deliberate.** SPEC
§3.6 gives subjects a canonical order — semester desc, name asc — *and then
exempts the top-level lists*, which are newest-created first (id desc). Home,
the education detail, and the semester filter all use the canonical order;
the Subjects/Educations/Grades list screens are a different thing, a record of
what you have most recently added.

So sectioning by semester isn't a presentation change. It requires the list to
be sorted by semester, which is a SPEC §3.6 amendment — and SPEC-POLISH
commits to changing no sort order, which is why this is here and not there.

**Worth deciding, not assumed.** The questions:

- Is "newest-created first" actually serving anyone on these screens? It's the
  order of least surprise after you add something, and nothing else. Against
  that: it's the only order in the app that no screen displays a cue for, so a
  list in it looks unordered.
- Semester numbers aren't comparable across educations. Several educations run
  in parallel, one per institution, so a "Semester 2" section would merge two
  unrelated semester 2s. The row still names its education, but the section
  header would be claiming a relationship that isn't there. Grouping by
  education first, semester within, is the honest version — and is two levels
  of nesting on a flat list.
- The grades list has the same shape of question and a better answer already
  written down: date sections (SPEC-POLISH §0.1, §2.4). Dates *are* comparable
  across parents, so grades may section cleanly while subjects don't. Whatever
  is decided here should explain why the two differ, if they do.
- All three lists became grids of tiles on macOS in the meantime
  (2026-08-20), which answers the *separation* half of the grades finding but
  not this one. It doesn't foreclose sections either — `LazyVGrid` takes
  `Section`, so a dated grid is buildable the day the sort order is settled.

Not scheduled.

## 5. A required description on a grade — tried and reverted

Built on 2026-08-21 and undone the next day. Recorded rather than deleted,
because the motivation was real and will come back.

**Why it was wanted.** A grade has no name field. An education and a subject
each have one, so their description is genuinely an extra; a grade's is the
only thing that can say what the number was for. Without it the grade detail
was titled "Grade", and a column of grades under one subject read as two
different kinds of row — some with a description heading them, some without.

**Why it was undone.** The rule could not do the job it was adopted for:

- **It doesn't fix existing data.** The change was validation-only — a
  `NOT NULL` column would mean inventing a description for every grade
  already saved without one, which is a data decision and not a rule change.
  So the grades that were ragged stayed ragged, permanently. The rule only
  prevented *new* ones, which was not the complaint.
- **It was a data rule for a layout problem, and the layout problem has a
  layout fix.** The raggedness was never "some rows have text": it was that
  the *date* sat on the first line for some rows and the second for others.
  Making the date lead and the description follow it fixes the appearance for
  every grade, old and new. That is what was built instead — see SPEC-POLISH
  §2.4.
- **Quick-add is the app's most frequent action** (SPEC §4) and this put a
  mandatory text field in it.
- It left a population that was valid at rest but unsavable on edit without
  inventing text for something recorded a year ago.

**If it comes back**, it should come back on its own argument — *a
description is worth having six months later* — and not on appearance, and it
should come with a decision about backfilling the existing rows, without
which it does not achieve what it looks like it achieves.

## 6. Deliberate gaps already recorded elsewhere

Not repeated here, to keep one list per item:

- **Undo, multi-select, user-controlled sort, empty-state onboarding** —
  [SPEC-POLISH.md](SPEC-POLISH.md) §4.
- **iCloud sync** — [SPEC.md](SPEC.md) §5, with the WAL and file-coordination
  notes that make it possible.
- **Multiple grading scales** — [SPEC.md](SPEC.md) §7. The schema stores raw
  numbers, so nothing structural blocks it; there's simply no UI or settings
  design for it.
