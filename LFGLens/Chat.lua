-- LFG Lens - Chat annotation, post collection, hyperlink handling
--
-- Pipeline for a public-channel message:
--   1. FindMatches: word-token scan (bails on >300 chars or >40
--      tokens - busy chat must never pay for this addon).
--   2. CollectPost: the message joins the Lens feed (author, plain
--      text, matched dungeon ids, timestamp). Deduped per
--      author+text within 60s, because the filter fires once per
--      visible chat frame.
--   3. Annotate: acronym tokens become |Hlfglens:|h links. One
--      meaning = direct link (Forever-new in sky blue, classic in
--      grey); several meanings = amber AMBIGUOUS link whose tooltip
--      lays out every meaning. Hover shows the facts; clicking a post
--      link pins/unpins that post and opens the Lens.
-- Nothing here sends, invites, whispers, or posts anything. Ever.
local _, ns = ...

ns.MAX_POSTS = 20
ns.POST_TTL = 120 -- seconds before an unpinned post fades out
ns.posts = {}
local nextPostID = 0

local COLOR_NEW = "66d9ff"
local COLOR_CLASSIC = "b8b8b8"
local COLOR_AMBIG = "ffd24d"

-- Word-token scan. Returns a list of { token, upper, dungeons } for
-- every token that resolves to at least one dungeon.
local function FindMatches(text)
    local out = {}
    if type(text) ~= "string" or #text > 300 then return out end
    local scanned = 0
    for token in text:gmatch("[%a]+") do
        scanned = scanned + 1
        if scanned > 40 then break end
        local hits = ns.Resolve(token)
        if #hits > 0 then
            out[#out + 1] = { token = token, upper = token:upper(), dungeons = hits }
        end
    end
    return out
end
ns.FindMatches = FindMatches

local function PrunePosts(now)
    now = now or (GetTime and GetTime()) or 0
    local kept = {}
    for i = 1, #ns.posts do
        local p = ns.posts[i]
        if p.pinned or (now - p.at) <= ns.POST_TTL then
            kept[#kept + 1] = p
        end
    end
    -- Cap: drop oldest UNPINNED first; pinned posts are only dropped
    -- past a hard ceiling so a pin-spree cannot grow the list forever.
    while #kept > ns.MAX_POSTS do
        local idx = nil
        for i = #kept, 1, -1 do
            if not kept[i].pinned then idx = i break end
        end
        if idx then
            table.remove(kept, idx)
        elseif #kept > ns.MAX_POSTS * 2 then
            table.remove(kept, #kept) -- all pinned: hard ceiling at 2x cap
        else
            break
        end
    end
    ns.posts = kept
end
ns.PrunePosts = PrunePosts

local function CollectPost(author, text, matches, now)
    now = now or (GetTime and GetTime()) or 0
    for i = 1, #ns.posts do
        local p = ns.posts[i]
        if p.author == author and p.text == text and (now - p.at) < 60 then
            return p
        end
    end
    nextPostID = nextPostID + 1
    local ids = {}
    for i = 1, #matches do
        for j = 1, #matches[i].dungeons do
            ids[matches[i].dungeons[j].id] = true
        end
    end
    local post = { id = nextPostID, author = author, text = text,
                   dungeons = ids, at = now, pinned = false }
    table.insert(ns.posts, 1, post)
    PrunePosts(now)
    return post
end
ns.CollectPost = CollectPost

local function FindPost(id)
    for i = 1, #ns.posts do
        if ns.posts[i].id == id then return ns.posts[i] end
    end
    return nil
end
ns.FindPost = FindPost

-- Replace matched acronym tokens with lfglens hyperlinks.
local function Annotate(text, matches, postID)
    if #matches == 0 then return text end
    local byUpper = {}
    for i = 1, #matches do byUpper[matches[i].upper] = matches[i] end
    local out = text:gsub("[%a]+", function(word)
        local m = byUpper[word:upper()]
        if not m then return word end
        local payload, color
        if #m.dungeons > 1 then
            payload = "ambig:" .. m.upper
            color = COLOR_AMBIG
        else
            local d = m.dungeons[1]
            payload = (postID and ("post:" .. postID .. ":") or "info:") .. d.id
            color = d.new and COLOR_NEW or COLOR_CLASSIC
        end
        return "|Hlfglens:" .. payload .. "|h|cff" .. color .. "[" .. word .. "]|h|r"
    end)
    return out
end
ns.Annotate = Annotate

-- One-line factual summary used by tooltips, the Lens focus line,
-- and /lfglens list. Unknown fields are said out loud, not hidden.
local function DescribeDungeon(d)
    local parts = {}
    parts[#parts + 1] = d.name
    if d.new then parts[#parts + 1] = "NEW in Forever" end
    parts[#parts + 1] = d.kind == "raid" and ("raid" .. (d.size and (" (" .. d.size .. ")") or "")) or "dungeon"
    if d.min and d.max then
        parts[#parts + 1] = "levels " .. d.min .. "-" .. d.max
    elseif d.note and d.note:find("Level ~30") then
        parts[#parts + 1] = "level ~30 (beta reports)"
    else
        parts[#parts + 1] = "level range not yet published"
    end
    if d.where then parts[#parts + 1] = d.where end
    return table.concat(parts, " - ")
end
ns.DescribeDungeon = DescribeDungeon

-- Tooltip line set for a link payload key (dungeon id or ambig:ACR).
local function InfoLines(key)
    local lines = {}
    local function addDungeon(d)
        lines[#lines + 1] = { text = DescribeDungeon(d),
            color = d.new and COLOR_NEW or COLOR_CLASSIC }
        if d.note then lines[#lines + 1] = { text = d.note, color = "cccccc" } end
        if d.ambigNote then lines[#lines + 1] = { text = d.ambigNote, color = COLOR_AMBIG } end
        if d.proposed then
            lines[#lines + 1] = { text = "Acronym is a community proposal, not settled slang - override it with /lfglens alias.", color = "888888" }
        end
    end
    local acr = key:match("^ambig:(.+)$")
    if acr then
        lines[#lines + 1] = { text = acr .. " can mean:", color = COLOR_AMBIG }
        local hits = ns.Resolve(acr)
        for i = 1, #hits do addDungeon(hits[i]) end
    else
        local d = ns.ById[key]
        if d then addDungeon(d) end
    end
    return lines
end
ns.InfoLines = InfoLines

-- Filter decision for the Lens window. Pure, so the harness can
-- drive it: mode is all|new|classic|mine; a post passes when ANY of
-- its dungeons passes; an unpublished level range always passes
-- "mine" (unknown is not a reason to hide a run you could join).
local function PostMatches(post, mode, playerLevel)
    if mode == "all" then return true end
    for id in pairs(post.dungeons) do
        local d = ns.ById[id]
        if d then
            if mode == "new" and d.new then return true end
            if mode == "classic" and not d.new then return true end
            if mode == "mine" then
                if (not d.min or playerLevel >= d.min)
                    and (not d.max or playerLevel <= d.max) then
                    return true
                end
            end
        end
    end
    return false
end
ns.PostMatches = PostMatches

-- The chat filter itself. Registered for CHAT_MSG_CHANNEL (General,
-- Trade, LFG and friends are all numbered channels on this client).
local function ChatFilter(_, _, msg, author, ...)
    if not (ns.db and ns.db.settings and ns.db.settings.enabled) then
        return false
    end
    if type(msg) ~= "string" or msg:find("lfglens:", 1, true) then
        return false -- never annotate our own links twice
    end
    local matches = FindMatches(msg)
    if #matches == 0 then return false end
    local post = nil
    if ns.db.settings.collect then
        post = CollectPost(author or "?", msg, matches)
        if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
    end
    return false, Annotate(msg, matches, post and post.id), author, ...
end
ns.ChatFilter = ChatFilter

local function OnLinkClick(payload)
    local postID, rest = payload:match("^post:(%d+):(.+)$")
    if postID then
        local post = FindPost(tonumber(postID))
        if post then
            post.pinned = not post.pinned
            ns.Print(post.pinned and "post pinned - it will outlive the 2-minute fade."
                or "post unpinned.")
        end
        if ns.UI and ns.UI.SetFocus then ns.UI.SetFocus(rest) end
        if ns.UI and ns.UI.Show then ns.UI.Show() end
        return
    end
    local key = payload:match("^info:(.+)$") or payload
    if ns.UI and ns.UI.SetFocus then ns.UI.SetFocus(key) end
    if ns.UI and ns.UI.Show then ns.UI.Show() end
end
ns.OnLinkClick = OnLinkClick

local function ShowLinkTooltip(frame, link)
    local payload = link:match("^lfglens:(.+)$")
    if not payload or not GameTooltip then return end
    local key = payload:match("^post:%d+:(.+)$") or payload:match("^info:(.+)$") or payload
    local lines = InfoLines(key)
    if #lines == 0 then return end
    GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
    for i = 1, #lines do
        local ln = lines[i]
        local r = tonumber(ln.color:sub(1, 2), 16) / 255
        local g = tonumber(ln.color:sub(3, 4), 16) / 255
        local b = tonumber(ln.color:sub(5, 6), 16) / 255
        if i == 1 and GameTooltip.SetText then
            GameTooltip:SetText(ln.text, r, g, b, 1, true)
        else
            GameTooltip:AddLine(ln.text, r, g, b, true)
        end
    end
    GameTooltip:Show()
end

local attached = false
local function Attach()
    if attached then return end
    attached = true
    if ChatFrame_AddMessageEventFilter then
        ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", ChatFilter)
    end
    if hooksecurefunc then
        hooksecurefunc("SetItemRef", function(link)
            if type(link) == "string" and link:sub(1, 8) == "lfglens:" then
                OnLinkClick(link:sub(9))
            end
        end)
    end
    for i = 1, 10 do
        local cf = _G["ChatFrame" .. i]
        if cf and cf.HookScript then
            cf:HookScript("OnHyperlinkEnter", ShowLinkTooltip)
            cf:HookScript("OnHyperlinkLeave", function()
                if GameTooltip then GameTooltip:Hide() end
            end)
        end
    end
    ns.chatAttached = true
end
ns.AttachChat = Attach
