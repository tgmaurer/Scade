<div align="center">

<img src="assets/icon/Scade-iOS-Default-1024x1024@1x.png" alt="Scade icon" width="128"/>

</div>

<h1 align="center">Scade</h1>

<div align="center">

A weighted grade tracker for macOS, on the Swiss 1–6 scale.

</div>

Educations hold subjects, subjects hold grades, and every average is weighted
on the way up.

It is built to be used, not published: there is no release download and no
App Store listing. You build it once and keep it in `/Applications` like any
other app. See [docs/STATUS.md](docs/STATUS.md) for what that means and what
it leaves unfinished.

## Requirements

- macOS 26.5 or later
- Xcode 26.5 or later, signed in with an Apple ID (a free account is enough —
  the app uses no capability that needs a paid membership)

## Install

Build a Release copy and move it into `/Applications`:

```sh
xcodebuild -project Scade.xcodeproj -scheme Scade -configuration Release \
  -destination 'platform=macOS' -derivedDataPath build
cp -R build/Build/Products/Release/Scade.app /Applications/
rm -rf build
```

The third command deletes the build tree. `-derivedDataPath build` keeps it
inside the repository rather than in `~/Library/Developer/Xcode/DerivedData`,
which is what makes it easy to find — and easy to forget. It holds a few
hundred megabytes of intermediates around a 10 MB app, it is already in
`.gitignore`, and the copy in `/Applications` does not depend on it.

Then open it from `/Applications` and keep it in the Dock. Gatekeeper is
satisfied because the app is signed with your own development certificate on
the machine that built it; it is not notarised, so it will not run on anyone
else's Mac without them building it too.

To update it, pull, run the same three commands, and replace the copy in
`/Applications`. Your data is not inside the app and is not touched by this.

## Where your data lives

One SQLite file, inside the app's sandbox container:

```
~/Library/Containers/com.tgmaurer.Scade/Data/Library/Application Support/Scade/scade.sqlite
```

That path is not a detail you normally need — it matters when you restore a
backup, below. Nothing else in the app writes outside its container except
the backups you ask for.

## Backing up

**Settings → Backup** (`⌘,`). Choose a folder once, then press **Back Up
Now** whenever you want a copy.

Choose a folder in **iCloud Drive** — say `iCloud Drive/Scade`. The point of
a backup is to survive this Mac, and one written to this Mac's disk does not.
The panel opens in iCloud Drive for that reason. Anywhere else works the same
way if you would rather your grades not sync.

Scade cannot pick the folder for you: it is sandboxed, so it can only write
where you have pointed it, and it remembers your choice as a security-scoped
bookmark rather than a path.

Each backup is a dated folder — `Scade Backup 2026-08-27` — holding four
files:

| File | What it is |
|---|---|
| `scade.sqlite` | The whole database. **This is the file that restores the app.** |
| `educations.csv` | One row per education |
| `subjects.csv` | One row per subject, `educationId` pointing at its education |
| `grades.csv` | One row per grade, `subjectId` pointing at its subject |

Backing up twice in one day refreshes that day's folder rather than making a
second one. Earlier days are never touched.

The CSVs are for reading — a spreadsheet, a script, anything that outlives
this app. They carry stored values rather than displayed ones, so `weight` is
the multiplier the app calculates with: `1.0` is the `100%` you see on
screen, `0.25` is `25%`. They are UTF-8 with a byte order mark and CRLF line
endings, which is what Excel needs to read umlauts correctly on a
double-click.

## Restoring

There is no Import button. Restoring is a file copy, and it has one rule:

1. **Quit Scade.** The app holds the database open, and will overwrite
   whatever you put there if it is still running.
2. Replace the live database with the one from your backup:

   ```sh
   cp "/path/to/Scade Backup 2026-08-27/scade.sqlite" \
     ~/Library/Containers/com.tgmaurer.Scade/Data/Library/Application\ Support/Scade/scade.sqlite
   ```

3. Open Scade. Everything from that backup is there.

If you would rather not overwrite, move the current file aside first instead
of deleting it — it is the only copy of anything you have not backed up.

## Repository layout

| Path | What's in it |
|---|---|
| `App/` | The `App` target: opens the database and hands it over |
| `ScadeKit/Sources/ScadeKit/` | Models, business logic, GRDB persistence |
| `ScadeKit/Sources/ScadeUI/` | Every screen |
| `ScadeKit/Tests/` | Unit tests for the logic and persistence |
| `UITests/` | End-to-end tests |
| `docs/` | The specs — start with `SPEC.md`, then `STATUS.md` |

## Built with

[GRDB.swift](https://github.com/groue/GRDB.swift) by Gwendal Roué — the SQLite
toolkit the whole persistence layer sits on. MIT licensed. It is Scade's only
dependency, and it is credited in the app as well, under **Settings → About**.

## Licence

GPL-3.0. See [LICENSE](LICENSE).
