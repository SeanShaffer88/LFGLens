# Changelog

## 0.1.0 — 2026-10-24 (pre-launch)

First build, for WoW: Forever (Interface 16001) only.

- Chat annotation on public channels: dungeon acronyms become clickable `lfglens:` links — Forever-new in sky blue, classic in grey, ambiguous in amber. Hover shows full name, kind/size, level range or an honest "not yet published", entrance hint, sourced notes, ambiguity warnings, and proposed-acronym disclaimers. Click pins/unpins the source post and opens the Lens focused on the meaning.
- The Lens window: newest-first feed of the last 20 dungeon posts with age stamps, 120-second fade for unpinned posts, pin survival to a 2× hard ceiling, author+text dedupe across chat frames, and filters All / New in Forever / Classic / My level (unpublished ranges always pass My level). Row click opens a whisper draft to the author. 15-second refresh while shown.
- Dictionary: 33 entries — the nine Forever-new dungeons named in reveal reporting (Hall of Thanes, Ruins of Lordaeron, Whelgar's Excavation, City of Dalaran, Blackmaw Hold, Drowned City, Krol'dok Stronghold, Alcaz Prison, Shaper's Terrace), the Dec 9 raids (Barrow Deeps, Hyjal Summit, returning Onyxia's Lair), and 21 classic dungeons/raids with their long-published level ranges. New-dungeon level ranges are recorded as unpublished, not invented; City of Dalaran carries its one sourced figure (~30, beta). New-dungeon acronyms are marked `proposed` in the data and labelled as proposals in the UI.
- Collisions resolved to both meanings: ST, DM, BD; ambiguity notes for HOT, DC, KS, HS.
- `/lfglens alias <ACR> = <dungeon>` repoints any acronym (persisted, wins over built-ins); `unalias` restores. Plus `list [new|classic|raids]`, `clear`, `on|off`, `debug`, `help`.
- Perf rails: messages over 300 characters or 40 tokens are never scanned; already-annotated text is never re-annotated.
- Local gate green (parse + TOC + dictionary audit + version consistency + mocked-API harness). **Runtime in the live Forever client is Unverified** — Forever launches Nov 4, 2026; see docs/VERIFICATION.md.
