# LFG Lens — Verification

## v0.1.0 (2026-10-24)

| Check | Result |
|---|---|
| Local gate (`python3 tools/gate.py`): Lua parse (luaparser) for all files | **PASS** (2026-10-24, run by Muse: parse ok ×4, schema 33 dungeons 0 problems, version 0.1.0 consistent, harness PASS — all 12 checks) |
| TOC cross-check: interface 16001, every .lua listed | Gate |
| Dictionary audit: 33 entries, 9 new dungeons all `proposed` with NO level range recorded, 2 new raids, classic entries all carry ranges, ST/DM/BD each resolve to exactly 2 dungeons | Gate |
| Version consistency: TOC == Core.lua == tools/package.py (0.1.0) | Gate |
| UI rule: SetBackdrop only in UI.lua, frame created with BackdropTemplate | Gate |
| Harness: dictionary resolution (collisions, singles, case, non-dungeon tokens) | Gate / harness |
| Harness: filter annotates ambiguous + new (sky) + classic (grey), collects posts, dedupes across frames, never re-annotates its own links, bails on overlong messages | Harness |
| Harness: info lines carry both meanings + collision warning + honest "not yet published" + Dalaran ~30 note | Harness |
| Harness: pin click survives 120 s expiry, unpinned fades, unpin works; alias repoints and unalias restores | Harness |
| Harness: PostMatches filters incl. My level (52–60 excludes a 42; unpublished range passes) | Harness |
| Harness: Lens window builds/shows/hides, row renders author, row click opens `/w` draft, filter cycle narrows the feed | Harness |
| **Live client (WoW: Forever) runtime** | **Unverified** — launches Nov 4, 2026. Field test per `docs/screenshots/CAPTURE.md`: watch a busy channel, hover ST/BD links, pin a post, alias one acronym to local slang. |

Labels: Verified / Partially Verified / Unverified. A green gate is
syntax-and-mock proof only, never a runtime claim.
