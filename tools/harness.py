#!/usr/bin/env python3
"""LFG Lens startup + chat-simulation harness.

Loads the addon files listed in the Camelot .toc against a mocked WoW
API using lupa, fires ADDON_LOADED -> PLAYER_LOGIN, then drives the
real code: the chat filter (annotation + collection), hyperlink info
and pin clicks, aliases, filters, post expiry, and the Lens window
(build, refresh, row-click whisper). Any Lua error fails the harness.

This proves parse/boot/logic against the mock. It does NOT prove
in-game behaviour - Unverified until a live-client run.
"""
import pathlib
import sys

import lupa

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / "LFGLens"

PRELUDE = r"""
CHATLOG = {}
NOW = 1000
GetTime = function() return NOW end
UnitLevel = function() return 42 end
FILTERS = {}
ChatFrame_AddMessageEventFilter = function(ev, fn) FILTERS[ev] = fn end
SETITEMREF_HOOK = nil
hooksecurefunc = function(name, fn) if name == "SetItemRef" then SETITEMREF_HOOK = fn end end
OPENCHAT = nil
ChatFrame_OpenChat = function(text) OPENCHAT = text end
C_Timer = { NewTicker = function() return {} end, After = function() end }

local function newFS()
    local fs = { _text = "" }
    local methods = {
        GetText = function() return fs._text end,
        SetText = function(_, t) fs._text = tostring(t or "") end,
    }
    return setmetatable(fs, { __index = function(_, k)
        if methods[k] then return methods[k] end
        return function(...) return nil end
    end })
end
FRAMES = {}
local function newFrame(kind, name, parent, template)
    local f = { _name = name or "", _kind = kind or "Frame", _scripts = {},
                _events = {}, _shown = true, _text = "" }
    local methods = {
        GetName = function() return f._name end,
        IsShown = function() return f._shown end,
        Show = function() f._shown = true end,
        Hide = function() f._shown = false end,
        SetText = function(_, t) f._text = tostring(t or "") end,
        GetText = function() return f._text end,
        SetScript = function(_, k, fn) f._scripts[k] = fn end,
        GetScript = function(_, k) return f._scripts[k] end,
        HookScript = function(_, k, fn) f._scripts[k] = fn end,
        RegisterEvent = function(_, e) f._events[e] = true end,
        UnregisterEvent = function(_, e) f._events[e] = nil end,
        CreateFontString = function() return newFS() end,
        StartMoving = function() end,
        StopMovingOrSizing = function() end,
    }
    if template and tostring(template):find("BackdropTemplate") then
        methods.SetBackdrop = function() end
        methods.SetBackdropColor = function() end
        methods.SetBackdropBorderColor = function() end
    end
    local CAPGATED = { SetBackdrop = true, SetBackdropColor = true,
                       SetBackdropBorderColor = true }
    setmetatable(f, { __index = function(_, k)
        if methods[k] then return methods[k] end
        if CAPGATED[k] then return nil end
        return function(...) return nil end
    end })
    FRAMES[#FRAMES + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = newFrame
UIParent = newFrame("Frame", "UIParent")
ChatFrame1 = newFrame("Frame", "ChatFrame1")
DEFAULT_CHAT_FRAME = { AddMessage = function(_, msg) CHATLOG[#CHATLOG + 1] = tostring(msg) end }
SlashCmdList = {}
GetBuildInfo = function() return "1.60.1", "70450", "Oct 2026", 16001 end

GameTooltip = newFrame("GameTooltip", "GameTooltip")
GameTooltip._lines = {}
GameTooltip.SetText = function(self, t) self._lines = { tostring(t) } end
GameTooltip.AddLine = function(self, t) self._lines[#self._lines + 1] = tostring(t) end
GameTooltip.SetOwner = function() end
"""

DRIVER = r"""
local report = {}
local function note(s) report[#report + 1] = s end
local function try(label, fn)
    local ok, e = pcall(fn)
    note(label .. ": " .. (ok and "ok" or ("FAIL " .. tostring(e))))
    if not ok then error(label) end
end
local NS = {}
for _, item in ipairs(FILES) do
    local fn, err = load(item.code, item.name)
    if not fn then note("LOADFAIL " .. item.name .. ": " .. tostring(err)); return table.concat(report, "\n") end
    local ok, e = pcall(fn, "LFGLens", NS)
    if not ok then note("RUNFAIL " .. item.name .. ": " .. tostring(e)); return table.concat(report, "\n") end
end
note("loaded " .. #FILES .. " files, dungeons=" .. #NS.Dungeons)
local function fire(ev, ...)
    for _, f in ipairs(FRAMES) do
        if f._events and f._events[ev] and f._scripts and f._scripts.OnEvent then
            local ok, e = pcall(f._scripts.OnEvent, f, ev, ...)
            if not ok then note("EVENTFAIL " .. ev .. ": " .. tostring(e)) end
        end
    end
end
fire("ADDON_LOADED", "LFGLens")
fire("PLAYER_LOGIN")
note("login fired, chatAttached=" .. tostring(NS.chatAttached))
local filter = FILTERS["CHAT_MSG_CHANNEL"]
assert(filter, "chat filter not registered")

try("dictionary resolves collisions and singles", function()
    assert(#NS.Resolve("ST") == 2, "ST should be ambiguous")
    assert(#NS.Resolve("DM") == 2, "DM should be ambiguous")
    assert(#NS.Resolve("BD") == 2, "BD should be ambiguous")
    assert(#NS.Resolve("HOT") == 1, "HOT single")
    assert(#NS.Resolve("rfc") == 1, "case-insensitive RFC")
    assert(#NS.Resolve("LFM") == 0, "LFM is not a dungeon")
end)
try("filter annotates ambiguous acronym and collects the post", function()
    local _, out = filter(nil, "CHAT_MSG_CHANNEL", "LFM ST need healer", "Alicia")
    assert(out and out:find("|Hlfglens:ambig:ST", 1, true), "no ambig link: " .. tostring(out))
    assert(#NS.posts == 1, "post not collected")
    assert(NS.posts[1].dungeons["shapersterrace"] and NS.posts[1].dungeons["sunkentemple"],
        "post dungeons wrong")
end)
try("same message via a second chat frame dedupes", function()
    filter(nil, "CHAT_MSG_CHANNEL", "LFM ST need healer", "Alicia")
    assert(#NS.posts == 1, "dedupe failed, posts=" .. #NS.posts)
end)
try("new dungeon gets a post link in the new colour; classic gets grey", function()
    local _, outNew = filter(nil, "CHAT_MSG_CHANNEL", "LFG HOT fresh run", "Borin")
    assert(outNew:find("|cFF66d9ff", 1, true) or outNew:find("66d9ff", 1, true), "new colour missing: " .. tostring(outNew))
    assert(outNew:find(":hallofthanes", 1, true), "hallofthanes payload missing")
    local _, outClassic = filter(nil, "CHAT_MSG_CHANNEL", "LFM BRD 2 dps", "Celia")
    assert(outClassic:find("b8b8b8", 1, true), "classic colour missing: " .. tostring(outClassic))
end)
try("our own annotated text is never re-annotated", function()
    local _, once = filter(nil, "CHAT_MSG_CHANNEL", "LFG HOT", "Dain")
    local _, twice = filter(nil, "CHAT_MSG_CHANNEL", once, "Dain")
    assert(twice == nil, "re-annotated an lfglens message")
end)
try("overlong message bails untouched", function()
    local long = "LFG HOT " .. ("x"):rep(320)
    local _, out = filter(nil, "CHAT_MSG_CHANNEL", long, "Elba")
    assert(out == nil, "annotated an overlong message")
end)
try("hyperlink info lines tell the whole story", function()
    local lines = NS.InfoLines("ambig:ST")
    local t = {}
    for i = 1, #lines do t[#t + 1] = lines[i].text end
    t = table.concat(t, "\n")
    assert(t:find("Shaper's Terrace", 1, true) and t:find("Sunken Temple", 1, true), "both meanings required: " .. t)
    assert(t:find("collision", 1, true), "ambiguity warning required")
    local bd = {}
    for i = 1, #NS.InfoLines("barrowdeeps") do bd[#bd + 1] = NS.InfoLines("barrowdeeps")[i].text end
    assert(table.concat(bd, "\n"):find("not yet published", 1, true), "barrow levels must be honestly unpublished")
    local cod = {}
    for i = 1, #NS.InfoLines("cityofdalaran") do cod[#cod + 1] = NS.InfoLines("cityofdalaran")[i].text end
    assert(table.concat(cod, "\n"):find("~30", 1, true), "city of dalaran should carry its beta level note")
end)
try("clicking a post link pins it; pinned survives expiry, unpinned fades", function()
    local post = NS.posts[1]
    NS.OnLinkClick("post:" .. post.id .. ":shapersterrace")
    assert(post.pinned == true, "pin did not stick")
    NOW = NOW + 10000
    NS.PrunePosts(NOW)
    local found = NS.FindPost(post.id)
    assert(found ~= nil, "pinned post was pruned")
    assert(#NS.posts == 1, "unpinned posts should have faded, posts=" .. #NS.posts)
    NS.OnLinkClick("post:" .. post.id .. ":shapersterrace")
    assert(post.pinned == false, "second click should unpin")
end)
try("user alias repoints an acronym; unalias restores", function()
    SlashCmdList["LFGLENS"]("alias BD = Barrow Deeps")
    local hits = NS.Resolve("BD")
    assert(#hits == 1 and hits[1].id == "barrowdeeps", "alias did not repoint BD")
    SlashCmdList["LFGLENS"]("unalias BD")
    assert(#NS.Resolve("BD") == 2, "unalias did not restore ambiguity")
end)
try("PostMatches filters behave", function()
    local brdPost = { dungeons = { brd = true } }
    local codPost = { dungeons = { cityofdalaran = true } }
    assert(NS.PostMatches(brdPost, "classic", 42) == true)
    assert(NS.PostMatches(brdPost, "new", 42) == false)
    assert(NS.PostMatches(brdPost, "mine", 42) == false, "BRD 52-60 should exclude a 42")
    assert(NS.PostMatches(brdPost, "mine", 55) == true)
    assert(NS.PostMatches(codPost, "mine", 42) == true, "unpublished range must pass mine")
    assert(NS.PostMatches(codPost, "new", 42) == true)
end)
try("Lens window builds, shows a row, row click opens a whisper", function()
    NOW = 2000
    NS.posts = {}
    filter(nil, "CHAT_MSG_CHANNEL", "LFG HOT fresh run", "Borin")
    SlashCmdList["LFGLENS"]("hide")
    SlashCmdList["LFGLENS"]("show")
    assert(LFGLensFrame and LFGLensFrame:IsShown(), "window not shown")
    local row = NS.UI.rows[1]
    assert(row.post and row.post.author == "Borin", "row 1 is not Borin's post")
    assert(row.fs:GetText():find("Borin", 1, true), "row text lacks author: " .. row.fs:GetText())
    row.button._scripts["OnClick"]()
    assert(OPENCHAT == "/w Borin ", "whisper not opened: " .. tostring(OPENCHAT))
    SlashCmdList["LFGLENS"]("hide")
    assert(not LFGLensFrame:IsShown(), "hide failed")
end)
try("filter cycle narrows the feed", function()
    SlashCmdList["LFGLENS"]("show")
    NS.db.settings.filter = "classic"
    NS.UI.Refresh()
    assert(NS.UI.rows[1].post == nil, "classic filter should hide the HOT post")
    NS.db.settings.filter = "all"
    NS.UI.Refresh()
    assert(NS.UI.rows[1].post ~= nil, "all filter should show it again")
end)
note("chat lines: " .. #CHATLOG)
note("DONE")
return table.concat(report, "\n")
"""


def toc_files(toc_name):
    lines = (ADDON / toc_name).read_text().splitlines()
    return [ln.strip() for ln in lines if ln.strip().endswith(".lua")]


def main():
    files = toc_files("LFGLens_Camelot.toc")
    rt = lupa.LuaRuntime(unpack_returned_tuples=True)
    rt.execute(PRELUDE)
    rt.globals().FILES = rt.table_from(
        [{"name": n, "code": (ADDON / n).read_text()} for n in files])
    out = rt.execute(DRIVER)
    print(f"--- harness (LFGLens_Camelot.toc: {', '.join(files)}) ---")
    print(out)
    bad = [ln for ln in out.splitlines() if "FAIL" in ln]
    if bad or "DONE" not in out:
        print("HARNESS: FAIL")
        sys.exit(1)
    print("HARNESS: PASS")


if __name__ == "__main__":
    main()
