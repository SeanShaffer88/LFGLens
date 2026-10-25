# LFG Lens — Features

## Chat annotation (v0.1.0)
- Registered on `CHAT_MSG_CHANNEL` (all numbered public channels: General, Trade, LFG, LocalDefense…).
- Acronym tokens become `lfglens:` hyperlinks: Forever-new = sky blue, classic = grey, ambiguous (2+ meanings) = amber.
- Hover tooltip: full name, NEW marker, dungeon/raid + size, level range or "not yet published", entrance hint, sourced notes, ambiguity warnings, and a "proposed acronym" disclaimer where the acronym is a community proposal.
- Click: pins/unpins the source post and opens the Lens focused on that meaning (via a guarded `SetItemRef` hook); plain info links just focus the Lens.
- Safety rails: skips messages over 300 chars or 40 tokens, skips anything already containing an `lfglens:` link, and does nothing at all while disabled.

## The Lens window
- BackdropTemplate frame with opaque WHITE8x8 panels (house Forever UI rules); movable; close button.
- Feed: newest first, max 20 posts; unpinned posts expire after 120 s; pinned posts survive to a hard 2× ceiling; per author+text dedupe inside 60 s covers multi-frame filter delivery.
- Age stamps (`12s`, `1m`…), author shown realm-shortened, post text truncated at 74 chars, pipes escaped.
- Filters cycle: All → New in Forever → Classic → My level (a post passes "My level" when any of its dungeons fits — and an unpublished range always passes, because unknown is not a reason to hide a run).
- Row click opens a whisper draft to the author (`ChatFrame_OpenChat`, with `ChatFrame_SendTell` fallback).
- Auto-refresh every 15 s while shown (age stamps and expiry stay honest).

## Dictionary & aliases
- 33 entries: 9 Forever-new dungeons, 3 raids (Barrow Deeps and Hyjal Summit new; Onyxia's Lair returning), 21 classic dungeons/raids.
- Headline collisions resolved to both meanings: ST, DM, BD — plus ambiguity notes for HOT (heal-over-time), DC (disconnect), KS (kill-steal), HS (Hearthstone).
- `/lfglens alias <ACR> = <name>`: case-insensitive name search, refuses ambiguous name matches with a candidate list; aliases persist in SavedVariables and override built-ins and proposals. `/lfglens unalias` restores.

## Settings (SavedVariables `LFGLensDB`, versioned)
- `enabled` (default on), `collect` (default on), `filter` (default all), `aliases` map. Posts are session-only and never saved.

## Deliberately not features
- No auto-invite, auto-whisper, auto-posting, or role/gear judgements of any kind.
- No addon comms — the Lens works with zero other users installed.
