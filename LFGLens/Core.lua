-- LFG Lens - Core
-- WoW: Forever (Interface 16001). Reads public channel chat, turns
-- dungeon acronyms into honest clickable links, and collects the
-- posts into one small window. Display and organisation only: it
-- never invites, whispers, posts, or judges a player's gear or role.
local ADDON, ns = ...

ns.VERSION = "0.1.0"

local function Print(msg)
    local chat = DEFAULT_CHAT_FRAME
    if chat and chat.AddMessage then
        chat:AddMessage("|cff66d9ffLFG Lens:|r " .. tostring(msg))
    end
end
ns.Print = Print

-- SavedVariables: settings + user aliases (posts are ephemeral chat
-- and are deliberately NOT saved). Version-stamped; a save from a
-- newer version is left untouched.
local DB_VERSION = 1
local function EnsureDB()
    if type(LFGLensDB) ~= "table" then LFGLensDB = {} end
    local db = LFGLensDB
    if type(db.settings) ~= "table" then db.settings = {} end
    if db.settings.enabled == nil then db.settings.enabled = true end
    if db.settings.collect == nil then db.settings.collect = true end
    if db.settings.filter == nil then db.settings.filter = "all" end
    if type(db.aliases) ~= "table" then db.aliases = {} end
    if type(db.version) ~= "number" then db.version = 0 end
    if db.version < DB_VERSION then db.version = DB_VERSION end
    ns.db = db
end
ns.EnsureDB = EnsureDB

local function FindDungeonByName(query)
    query = (query or ""):lower()
    if query == "" then return nil end
    if ns.ById[query] then return ns.ById[query] end
    local hits = {}
    for i = 1, #ns.Dungeons do
        local d = ns.Dungeons[i]
        if d.name:lower():find(query, 1, true) then hits[#hits + 1] = d end
    end
    if #hits == 1 then return hits[1] end
    return nil, hits
end
ns.FindDungeonByName = FindDungeonByName

-- /lfglens alias <ACR> = <dungeon name or id>
-- The user's word wins: the acronym is repointed to that one dungeon,
-- overriding built-ins and proposals alike. Stored in SavedVariables.
local function AliasCommand(rest)
    local acr, target = rest:match("^%s*(%S+)%s*=%s*(.-)%s*$")
    if not acr or not target or target == "" then
        Print("usage: /lfglens alias ST = Shaper's Terrace  (your acronym then means that one dungeon, everywhere)")
        return
    end
    local d, candidates = FindDungeonByName(target)
    if not d then
        if candidates and #candidates > 1 then
            local names = {}
            for i = 1, #candidates do names[#names + 1] = candidates[i].name end
            Print("'" .. target .. "' matches several dungeons: " ..
                table.concat(names, ", ") .. " - be more specific.")
        else
            Print("no dungeon matches '" .. target .. "'. /lfglens list shows them all.")
        end
        return
    end
    ns.db.aliases[acr:upper()] = d.id
    ns.BuildIndex()
    Print(acr:upper() .. " now means " .. d.name .. " (your alias; delete with /lfglens unalias " ..
        acr:upper() .. ").")
end

local function ListCommand(rest)
    local want = (rest or ""):lower()
    for i = 1, #ns.Dungeons do
        local d = ns.Dungeons[i]
        local show = want == "" or want == "all"
            or (want == "new" and d.new)
            or (want == "classic" and not d.new)
            or (want == "raids" and d.kind == "raid")
        if show then
            Print(table.concat(d.acronyms, "/") .. " - " .. ns.DescribeDungeon(d) ..
                (d.proposed and " [proposed acronym]" or ""))
        end
    end
end

local function SlashHandler(msg)
    EnsureDB()
    local cmd, rest = "", ""
    if type(msg) == "string" then
        cmd = (msg:match("^%s*(%S+)") or ""):lower()
        rest = msg:match("^%s*%S+%s+(.-)%s*$") or ""
    end
    if cmd == "show" or cmd == "" then
        if ns.UI and ns.UI.Toggle then ns.UI.Toggle() end
    elseif cmd == "hide" then
        if ns.UI and ns.UI.Hide then ns.UI.Hide() end
    elseif cmd == "list" then
        ListCommand(rest)
    elseif cmd == "alias" then
        AliasCommand(rest)
    elseif cmd == "unalias" then
        local acr = rest:upper():gsub("%s", "")
        if ns.db.aliases[acr] then
            ns.db.aliases[acr] = nil
            ns.BuildIndex()
            Print("alias " .. acr .. " removed; the built-in meaning is back.")
        else
            Print("you have no alias for " .. acr .. ".")
        end
    elseif cmd == "clear" then
        ns.posts = {}
        if ns.UI and ns.UI.Refresh then ns.UI.Refresh() end
        Print("Lens feed cleared.")
    elseif cmd == "on" then
        ns.db.settings.enabled = true
        Print("annotation on.")
    elseif cmd == "off" then
        ns.db.settings.enabled = false
        Print("annotation off. Chat flows untouched until you turn it back on.")
    elseif cmd == "debug" then
        Print("version " .. ns.VERSION .. " | dungeons=" .. #ns.Dungeons ..
            " posts=" .. #(ns.posts or {}) .. " chatAttached=" .. tostring(ns.chatAttached))
        if GetBuildInfo then
            local v, b = GetBuildInfo()
            Print("client build: " .. tostring(v) .. " (" .. tostring(b) .. ")")
        end
    elseif cmd == "help" then
        Print("Commands: /lfglens - toggle the Lens window | /lfglens list [new|classic|raids] - the dictionary | /lfglens alias ACR = Dungeon Name - your word wins | /lfglens unalias ACR | /lfglens clear | /lfglens on|off | /lfglens debug")
    else
        Print("unknown command '" .. cmd .. "' - /lfglens help lists them all.")
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        EnsureDB()
        ns.BuildIndex()
    elseif event == "PLAYER_LOGIN" then
        EnsureDB()
        ns.BuildIndex()
        SLASH_LFGLENS1 = "/lfglens"
        SLASH_LFGLENS2 = "/lens"
        SlashCmdList["LFGLENS"] = SlashHandler
        if ns.AttachChat then ns.AttachChat() end
        if ns.UI and ns.UI.Build then ns.UI.Build() end
        Print("loaded v" .. ns.VERSION .. " - " .. #ns.Dungeons ..
            " dungeons in the dictionary. /lfglens opens the Lens.")
    end
end)
