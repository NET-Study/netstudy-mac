# NET Study

A native Apple silicon macOS study Bible reader built on the public NET Bible API
(`https://labs.bible.org/api/`). SwiftUI, no third-party dependencies, ~2.5 MB app.

![app](docs/screenshot.png)

## What it does

- **Full reference navigation** — 66 books with chapter grids, plus a "Go to" field
  that understands `John 3:16`, `rom 8:28-39`, `Ps 23`, `Jude 3`, and semicolon lists
  like `John 3:16-17; Psalms 23`.
- **Reading experience** — serif or sans text, adjustable size and column width,
  light/dark/system appearance, generous line spacing.
- **Verse actions** — click a verse number (or the ellipsis that appears on hover) to
  highlight in five colors, bookmark, copy with reference, or write a note.
- **Saved & Notes** — bookmarks and study notes live in the sidebar and jump straight
  back to the passage.
- **Verse of the Day and random passages** for when you don't know where to land.
- **Offline cache** — every passage you read is cached to disk, so recent readings
  still open without a connection.

## Install

The built app is at `build/NET Study.app`. Copy it wherever you like:

```
cp -R "build/NET Study.app" ~/Applications/
open ~/Applications/"NET Study.app"
```

The app is ad-hoc signed (no developer certificate). If macOS ever complains, right
click the app and choose **Open**.

Requires macOS 14 or later on Apple silicon.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `⌘F` | Focus the reference field |
| `⌘D` | Verse of the Day |
| `⌘R` | Random verse |
| `⌘]` / `⌘[` | Next / previous chapter |
| `⌘⌥S` | Toggle sidebar |

## Build from source

```bash
./build.sh
```

The script compiles `Sources/*.swift`, generates the icon, assembles the `.app`
bundle, and ad-hoc signs it.

One toolchain note: SwiftUI in the macOS 27 SDK declares `@State` and friends as
macros that live in Xcode's plugin directory, which the Command Line Tools don't
ship. `build.sh` therefore compiles against the `MacOSX26.5.sdk` (still a plain
property-wrapper SwiftUI) and deploys to macOS 14+, which runs fine on newer
systems. If you have full Xcode, you can switch `SDK` to `xcrun --show-sdk-path`.

## Data

Notes, highlights, bookmarks, history, and preferences are stored locally at:

```
~/Library/Application Support/NETStudy/state.json
```

Passage cache lives in `~/Library/Application Support/NETStudy/passages/`. Nothing
is sent anywhere except the passage reference itself to `labs.bible.org`.

## Attribution

Scripture text is the **New English Translation (NET Bible)**, © Biblical Studies
Press, served through the public NET Bible API at `labs.bible.org`. This app is an
unofficial reader and is not affiliated with Bible.org.

The GPL-3.0 license was specifically chosen to keep anyone from using the free-to-use and copyrighted NET Bible for illegal commercial gain.
