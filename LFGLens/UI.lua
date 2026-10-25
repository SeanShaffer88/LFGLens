-- LFG Lens - The Lens window
-- One small window: a focus line (what the last clicked acronym
-- means, in full) and the collected dungeon posts, newest first.
-- Built per the house Forever UI rules: the frame is created WITH
-- BackdropTemplate (plain frames have no SetBackdrop on this
-- client), panels are opaque WHITE8x8 tints (never translucent
-- tooltip art, which veils text parented under it), and every
-- FontString is parented to the panel it sits on.
local _, ns = ...

ns.UI = ns.UI or {}
local UI = ns.UI
local MAX_ROWS = 10

local function AgeText(at, now)
    local age = math.max(0, math.floor(now - at))
    if age < 60 then return age .. "s" end
    return math.floor(age / 60) .. "m"
end
UI.AgeText = AgeText

local function RowText(post, now)
    local who = (post.author or "?"):gsub("%-.*", "")
    local body = (post.text or ""):gsub("|", "||")
    if #body > 74 then body = body:sub(1, 71) .. "..." end
    local pin = post.pinned and "|cffffd24dPIN|r " or ""
    return pin .. "|cff888888" .. AgeText(post.at, now) .. "|r " ..
        "|cffffffff" .. who .. ":|r " .. body
end
UI.RowText = RowText

local function VisiblePosts()
    local out = {}
    local mode = (ns.db and ns.db.settings and ns.db.settings.filter) or "all"
    local level = (UnitLevel and UnitLevel("player")) or 60
    local now = (GetTime and GetTime()) or 0
    ns.PrunePosts(now)
    for i = 1, #ns.posts do
        if ns.PostMatches(ns.posts[i], mode, level) then
            out[#out + 1] = ns.posts[i]
        end
    end
    return out
end
UI.VisiblePosts = VisiblePosts

local function Refresh()
    if not UI.frame then return end
    local mode = (ns.db and ns.db.settings and ns.db.settings.filter) or "all"
    if UI.filterLabel then
        UI.filterLabel:SetText("Filter: " .. mode .. " (click to cycle)")
    end
    local posts = VisiblePosts()
    for i = 1, MAX_ROWS do
        local row = UI.rows[i]
        local post = posts[i]
        if post then
            row.post = post
            row.fs:SetText(RowText(post, (GetTime and GetTime()) or 0))
            row.button:Show()
        else
            row.post = nil
            row.button:Hide()
        end
    end
    if UI.emptyLabel then
        if #posts == 0 then
            UI.emptyLabel:SetText("No dungeon posts yet. LFG Lens collects them from public channels as they scroll by - acronyms in chat are links; hover for the full name, click to pin a post here.")
            UI.emptyLabel:Show()
        else
            UI.emptyLabel:Hide()
        end
    end
end
UI.Refresh = Refresh

local FILTER_ORDER = { "all", "new", "classic", "mine" }
local function CycleFilter()
    local cur = ns.db.settings.filter or "all"
    local idx = 1
    for i = 1, #FILTER_ORDER do
        if FILTER_ORDER[i] == cur then idx = i break end
    end
    ns.db.settings.filter = FILTER_ORDER[(idx % #FILTER_ORDER) + 1]
    Refresh()
end
UI.CycleFilter = CycleFilter

local function SetFocus(key)
    UI.focusKey = key
    if not UI.focusLabel then return end
    local lines = ns.InfoLines(key)
    local texts = {}
    for i = 1, math.min(#lines, 3) do texts[#texts + 1] = lines[i].text end
    UI.focusLabel:SetText(table.concat(texts, "\n"))
end
UI.SetFocus = SetFocus

local function Show()
    if not UI.frame then UI.Build() end
    if UI.frame then UI.frame:Show() Refresh() end
end
UI.Show = Show

local function Hide()
    if UI.frame then UI.frame:Hide() end
end
UI.Hide = Hide

local function Toggle()
    if UI.frame and UI.frame:IsShown() then Hide() else Show() end
end
UI.Toggle = Toggle

local function WhisperAuthor(post)
    if not post or not post.author then return end
    if ChatFrame_OpenChat then
        ChatFrame_OpenChat("/w " .. post.author .. " ")
    elseif ChatFrame_SendTell then
        ChatFrame_SendTell(post.author)
    else
        ns.Print("whisper " .. post.author .. " - your client exposes no tell helper to addons.")
    end
end
UI.WhisperAuthor = WhisperAuthor

local function Build()
    if UI.frame then return end
    local f = CreateFrame("Frame", "LFGLensFrame", UIParent, "BackdropTemplate")
    f:SetSize(460, 320)
    f:SetPoint("CENTER")
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        f:SetBackdropColor(0.05, 0.05, 0.07, 0.97)
        f:SetBackdropBorderColor(0.4, 0.4, 0.45, 1)
    end
    f:SetMovable(true)
    f:EnableMouse(true)
    if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    f:Hide()
    UI.frame = f

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 14, -10)
    title:SetText("|cff66d9ffLFG Lens|r - dungeon posts, untangled")
    UI.title = title

    local filterBtn = CreateFrame("Button", nil, f)
    filterBtn:SetSize(190, 20)
    filterBtn:SetPoint("TOPRIGHT", -36, -8)
    local fl = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fl:SetPoint("LEFT")
    fl:SetText("Filter: all (click to cycle)")
    filterBtn:SetScript("OnClick", CycleFilter)
    UI.filterBtn, UI.filterLabel = filterBtn, fl

    local close = CreateFrame("Button", nil, f)
    close:SetSize(22, 20)
    close:SetPoint("TOPRIGHT", -8, -8)
    local cl = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cl:SetPoint("CENTER")
    cl:SetText("x")
    close:SetScript("OnClick", Hide)
    UI.closeBtn = close

    local focus = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    focus:SetPoint("TOPLEFT", 14, -34)
    focus:SetPoint("TOPRIGHT", -14, -34)
    focus:SetJustifyH("LEFT")
    if focus.SetWordWrap then focus:SetWordWrap(true) end
    focus:SetText("Click an acronym in chat to see exactly what it means here - including when it can mean two dungeons at once.")
    UI.focusLabel = focus

    UI.rows = {}
    for i = 1, MAX_ROWS do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(432, 20)
        btn:SetPoint("TOPLEFT", 14, -78 - (i - 1) * 22)
        local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT")
        fs:SetJustifyH("LEFT")
        btn:SetScript("OnClick", function()
            local row = UI.rows[i]
            if row and row.post then WhisperAuthor(row.post) end
        end)
        btn:Hide()
        UI.rows[i] = { button = btn, fs = fs, post = nil }
    end

    local empty = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    empty:SetPoint("TOPLEFT", 14, -82)
    empty:SetPoint("TOPRIGHT", -14, -82)
    empty:SetJustifyH("LEFT")
    if empty.SetWordWrap then empty:SetWordWrap(true) end
    UI.emptyLabel = empty

    if C_Timer and C_Timer.NewTicker then
        C_Timer.NewTicker(15, function()
            if UI.frame and UI.frame:IsShown() then Refresh() end
        end)
    end
    SetFocus("ambig:ST")
    Refresh()
end
UI.Build = Build
