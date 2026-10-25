# LFG Lens — Build Spec (v0.1.0)

The full five-addon spec bundle lives with the project records as
`wow-forever-addon-specs-all-five.md`. This is the LFG Lens summary.

**Client:** WoW: Forever only — Interface 16001, `LFGLens_Camelot.toc`.
No addon comms, no combat surface, no automation: the addon reads
public channel chat and organises it.

**MVP (as built):**
1. `CHAT_MSG_CHANNEL` message-event filter: word-token acronym scan
   (caps: 300 chars / 40 tokens), matched tokens rewritten as
   `lfglens:` hyperlinks — hover tooltip with full facts and both
   meanings for ambiguous acronyms; click pins/unpins the post.
2. Lens window (BackdropTemplate, opaque WHITE8x8 panels): last 20
   posts, age stamps, 120 s fade, filters All/New/Classic/My level,
   row click = whisper draft.
3. Dictionary of 33 with user aliases in SavedVariables that override
   any built-in or proposed acronym.

**Data rules (load-bearing):** new-dungeon names from reveal
reporting only; level ranges for new dungeons are nil (unpublished)
in the data and the gate FAILS if one appears; new-dungeon acronyms
carry `proposed = true` and are labelled as proposals in the UI;
classic ranges are the long-published Classic ones.

**Spike list (live build, Nov 4):** confirm message-event filter
arg layout on numbered channels; confirm custom hyperlink hover via
chat-frame OnHyperlinkEnter; confirm SetItemRef hook behaviour for
non-item links; watch busy-city chat for filter cost.

**Kill criterion:** if the live build's chat filters cannot rewrite
channel text, the annotation half dies — ship the Lens as a
dictionary + manual-post window or not at all; do not move to
frame-replacement hacks.
