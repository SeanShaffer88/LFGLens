# LFG Lens

## TL;DR

LFG Lens is a tiny World of Warcraft: Forever addon that untangles dungeon chat. Forever has no dungeon finder, so groups form in public channels, in acronyms, at scroll speed — and Forever's nine new dungeons collide head-on with twenty-year-old abbreviations: **ST** is now both the Sunken Temple *and* Shaper's Terrace, **BD** is both Blackrock Depths *and* the new Barrow Deeps raid, **DM** still means two dungeons at once. LFG Lens turns every dungeon acronym in channel chat into a clickable link: hover it for the full name, level range, entrance and an explicit "this can also mean…" warning; click it to pin that post into the small Lens window, where dungeon posts are collected with age stamps instead of scrolling away. A `/lfglens alias` command lets you repoint any acronym the moment your server's slang settles — your word wins over the shipped dictionary, which marks every new-dungeon acronym as what it honestly is: a proposal, not settled slang.

See also: `FEATURES.md`, `DESCRIPTION.md`, `CHANGELOG.md`, `docs/SPEC.md`, `docs/VERIFICATION.md`.

## What it does

- **Chat links** — acronyms in public channels (General, Trade, LFG…) become links. Forever-new dungeons are sky blue, classic dungeons grey, ambiguous acronyms amber. Hover: full name, kind, level range (or an honest "not yet published"), entrance hint, notes, and both meanings when there are two.
- **The Lens window** (`/lfglens`) — the last 20 dungeon posts with age stamps; unpinned posts fade after 2 minutes. Filter: All / New in Forever / Classic / My level. Click a post to open a whisper to its author. Click an acronym in chat to pin/unpin its post and focus its meaning at the top of the window.
- **A dictionary you can overrule** — `/lfglens list` prints all 33 entries (9 new dungeons, 3 raids, 21 classic). `/lfglens alias ST = Shaper's Terrace` repoints an acronym everywhere, stored between sessions; `/lfglens unalias ST` restores the built-in meaning.

## Commands

- `/lfglens` or `/lens` — toggle the Lens window
- `/lfglens list [new|classic|raids]` — print the dictionary
- `/lfglens alias <ACR> = <dungeon name>` / `/lfglens unalias <ACR>`
- `/lfglens clear` — empty the feed · `/lfglens on|off` — annotation
- `/lfglens debug` — version, dictionary size, hook status

## Install

Unzip so the `LFGLens` folder sits in your WoW: Forever client's `Interface/AddOns/` folder. Forever only (interface 16001, `LFGLens_Camelot.toc`).

## Honest limits

- **v0.1.0 is a pre-launch build.** Local gate green (parse, dictionary audit, mocked-API harness — `docs/VERIFICATION.md`), but it has **not run in the live client**; Forever launches November 4, 2026.
- **New-dungeon data is thin because the facts are thin.** The nine names come from reveal reporting (TheNerdWire / "What's Next" summaries, via the Oct 2026 research); almost no level ranges or entrances are published, so those fields say "not yet published" instead of guessing. City of Dalaran carries its one sourced figure: ~30 content in the beta.
- **New-dungeon acronyms are proposals.** Nobody has standardised them yet; that's the gap this addon fills, and `alias` exists so the dictionary can follow real slang from day one.
- **Chat cost is capped:** messages over 300 characters or 40 words are never scanned, and already-annotated text is never re-annotated.
- LFG Lens never invites, whispers, posts, or scores anyone. It reads chat and organises it — nothing else.

## Screenshots

From real runs only, after launch (list in `docs/screenshots/CAPTURE.md`). No placeholders.

## License

MIT — see `LICENSE`.
