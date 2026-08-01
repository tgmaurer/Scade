# Scade — Backlog

Functional changes wanted after v1: new behaviour, new rules, new data.

Three documents, three jobs:

| | |
|---|---|
| [SPEC.md](SPEC.md) | the v1 functional contract — what the app does |
| [SPEC-POLISH.md](SPEC-POLISH.md) | how it looks and feels; presentation and interaction only |
| **SPEC-BACKLOG.md** | behaviour that isn't built and isn't v1 |

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

## 3. Deliberate gaps already recorded elsewhere

Not repeated here, to keep one list per item:

- **Undo, multi-select, user-controlled sort, empty-state onboarding** —
  [SPEC-POLISH.md](SPEC-POLISH.md) §4.
- **iCloud sync** — [SPEC.md](SPEC.md) §5, with the WAL and file-coordination
  notes that make it possible.
- **Multiple grading scales** — [SPEC.md](SPEC.md) §7. The schema stores raw
  numbers, so nothing structural blocks it; there's simply no UI or settings
  design for it.
