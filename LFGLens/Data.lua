-- LFG Lens - Dungeon + acronym dictionary
--
-- PROVENANCE (read before editing):
-- * Forever-NEW dungeons: the nine names are transcribed from the
--   Oct 23, 2026 research report (~/workspace/research_notes/
--   wow-forever-retail-hidden-secrets-collec-20261023-0535/report.md),
--   which cites TheNerdWire / "What's Next" summaries. The Dec 9 raids
--   (Barrow Deeps 10-player, Hyjal Summit 20-player, Onyxia's Lair
--   40-player in some schedules - the research notes the conflict)
--   come from the same sources via the Oct 19-20 addon research.
-- * Almost NO level ranges or entrances are published for the new
--   dungeons. Those fields are nil (= "not yet published", shown
--   honestly in the UI) except where a source states one: City of
--   Dalaran is "~30 content" (Warcraft Tavern, via SecretGPS), Hall
--   of Thanes is "under Ironforge" and Shaper's Terrace is in
--   Un'Goro (research report parentheticals).
-- * The acronyms for the NEW dungeons are OUR PROPOSALS (field
--   `proposed = true`): the community has not standardised them yet,
--   which is the entire reason this addon exists. Users can override
--   any of them with /lfglens alias the moment real slang settles.
-- * Classic entries are the long-standing community acronym
--   dictionary with the long-published Classic level ranges; they are
--   the inherited-content baseline Forever players bring with them.
--   If Forever's content differs, prune entries in a data update -
--   every entry is one table row.
--
-- Fields: id, name, acronyms {..}, kind "dungeon"|"raid",
-- new (Forever-original content), min/max (nil = unpublished),
-- where (entrance/zone hint or nil), size (raid size or nil),
-- ambigNote (why this acronym also means something else, or nil),
-- proposed (true when the acronym is our proposal, not settled slang).
local _, ns = ...

ns.Dungeons = ns.Dungeons or {}
local function Add(d) ns.Dungeons[#ns.Dungeons + 1] = d end

-- ============ Forever-NEW dungeons (9) ============

Add({ id = "hallofthanes", name = "Hall of Thanes", acronyms = { "HOT" },
      kind = "dungeon", new = true, where = "Under Ironforge", proposed = true,
      ambigNote = "HOT also means a heal-over-time spell. Context decides - LFG Lens shows both." })
Add({ id = "ruinsoflordaeron", name = "Ruins of Lordaeron", acronyms = { "ROL" },
      kind = "dungeon", new = true, proposed = true })
Add({ id = "whelgars", name = "Whelgar's Excavation", acronyms = { "WES" },
      kind = "dungeon", new = true, proposed = true })
Add({ id = "cityofdalaran", name = "City of Dalaran", acronyms = { "COD" },
      kind = "dungeon", new = true, proposed = true,
      note = "Level ~30 content in the beta (Warcraft Tavern). Home of the secret boss Lyn the Ignored." })
Add({ id = "blackmawhold", name = "Blackmaw Hold", acronyms = { "BH", "BMH" },
      kind = "dungeon", new = true, proposed = true })
Add({ id = "drownedcity", name = "Drowned City", acronyms = { "DC" },
      kind = "dungeon", new = true, proposed = true,
      ambigNote = "DC also means a disconnect. In an LFG post it almost always means this dungeon." })
Add({ id = "kroldok", name = "Krol'dok Stronghold", acronyms = { "KS" },
      kind = "dungeon", new = true, proposed = true,
      ambigNote = "KS also means kill-steal in group chat slang." })
Add({ id = "alcazprison", name = "Alcaz Prison", acronyms = { "AP" },
      kind = "dungeon", new = true, proposed = true })
Add({ id = "shapersterrace", name = "Shaper's Terrace", acronyms = { "ST" },
      kind = "dungeon", new = true, where = "Un'Goro Crater", proposed = true,
      ambigNote = "ST is also the Sunken Temple (Temple of Atal'Hakkar). This is Forever's headline acronym collision - check which one the poster means." })

-- ============ Forever raids (Dec 9) ============

Add({ id = "barrowdeeps", name = "Barrow Deeps", acronyms = { "BD" },
      kind = "raid", new = true, size = 10, proposed = true,
      note = "Raid, unlocks Dec 9 (research reports).",
      ambigNote = "BD is also how many players shorten Blackrock Depths (BRD). Raid posts mean Barrow Deeps; leveling posts usually mean BRD." })
Add({ id = "hyjalsummit", name = "Hyjal Summit", acronyms = { "HS" },
      kind = "raid", new = true, size = 20, proposed = true,
      note = "Raid, unlocks Dec 9 (research reports).",
      ambigNote = "HS also means your Hearthstone. 'LFM HS' in December means the raid." })
Add({ id = "onyxia", name = "Onyxia's Lair", acronyms = { "ONY" },
      kind = "raid", new = false, size = 40, min = 60, max = 60,
      note = "Returning raid in Forever's schedules (40-player in some schedules - sources conflict, research notes)." })

-- ============ Classic dungeons + raids (inherited dictionary) ============

Add({ id = "rfc", name = "Ragefire Chasm", acronyms = { "RFC" },
      kind = "dungeon", new = false, min = 13, max = 18, where = "Orgrimmar" })
Add({ id = "deadmines", name = "The Deadmines", acronyms = { "DM", "VC" },
      kind = "dungeon", new = false, min = 17, max = 26, where = "Westfall",
      ambigNote = "DM is also Dire Maul. Westfall groups mean Deadmines (VC = VanCleef); level 55+ groups mean Dire Maul." })
Add({ id = "wc", name = "Wailing Caverns", acronyms = { "WC" },
      kind = "dungeon", new = false, min = 17, max = 24, where = "The Barrens" })
Add({ id = "sfk", name = "Shadowfang Keep", acronyms = { "SFK" },
      kind = "dungeon", new = false, min = 22, max = 30, where = "Silverpine Forest" })
Add({ id = "bfd", name = "Blackfathom Deeps", acronyms = { "BFD" },
      kind = "dungeon", new = false, min = 24, max = 32, where = "Ashenvale" })
Add({ id = "stockade", name = "The Stockade", acronyms = { "STOCKS" },
      kind = "dungeon", new = false, min = 24, max = 32, where = "Stormwind City" })
Add({ id = "gnomeregan", name = "Gnomeregan", acronyms = { "GNOMER" },
      kind = "dungeon", new = false, min = 29, max = 38, where = "Dun Morogh" })
Add({ id = "rfk", name = "Razorfen Kraul", acronyms = { "RFK" },
      kind = "dungeon", new = false, min = 25, max = 35, where = "The Barrens" })
Add({ id = "sm", name = "Scarlet Monastery", acronyms = { "SM" },
      kind = "dungeon", new = false, min = 28, max = 45, where = "Tirisfal Glades",
      note = "Four wings (Graveyard, Library, Armory, Cathedral); the acronym covers all of them." })
Add({ id = "rfd", name = "Razorfen Downs", acronyms = { "RFD" },
      kind = "dungeon", new = false, min = 37, max = 46, where = "The Barrens" })
Add({ id = "uldaman", name = "Uldaman", acronyms = { "ULDA" },
      kind = "dungeon", new = false, min = 41, max = 51, where = "Badlands" })
Add({ id = "zf", name = "Zul'Farrak", acronyms = { "ZF" },
      kind = "dungeon", new = false, min = 42, max = 49, where = "Tanaris" })
Add({ id = "maraudon", name = "Maraudon", acronyms = { "MARA" },
      kind = "dungeon", new = false, min = 46, max = 55, where = "Desolace" })
Add({ id = "sunkentemple", name = "Temple of Atal'Hakkar (Sunken Temple)", acronyms = { "ST" },
      kind = "dungeon", new = false, min = 50, max = 60, where = "Swamp of Sorrows",
      ambigNote = "ST is also Shaper's Terrace, Forever's new Un'Goro dungeon. This is the headline acronym collision - check which one the poster means." })
Add({ id = "brd", name = "Blackrock Depths", acronyms = { "BRD", "BD" },
      kind = "dungeon", new = false, min = 52, max = 60, where = "Blackrock Mountain",
      ambigNote = "Players shorten BRD to BD - which is also Barrow Deeps, Forever's new raid. Leveling posts usually mean BRD; raid posts mean Barrow Deeps." })
Add({ id = "lbrs", name = "Lower Blackrock Spire", acronyms = { "LBRS" },
      kind = "dungeon", new = false, min = 55, max = 60, where = "Blackrock Mountain" })
Add({ id = "ubrs", name = "Upper Blackrock Spire", acronyms = { "UBRS" },
      kind = "dungeon", new = false, min = 55, max = 60, where = "Blackrock Mountain", size = 10 })
Add({ id = "diremaul", name = "Dire Maul", acronyms = { "DM" },
      kind = "dungeon", new = false, min = 55, max = 60, where = "Feralas",
      ambigNote = "DM is also The Deadmines. Level 55+ groups mean Dire Maul; Westfall groups mean Deadmines." })
Add({ id = "stratholme", name = "Stratholme", acronyms = { "STRAT" },
      kind = "dungeon", new = false, min = 58, max = 60, where = "Eastern Plaguelands" })
Add({ id = "scholomance", name = "Scholomance", acronyms = { "SCHOLO" },
      kind = "dungeon", new = false, min = 58, max = 60, where = "Western Plaguelands" })
Add({ id = "mc", name = "Molten Core", acronyms = { "MC" },
      kind = "raid", new = false, size = 40, min = 60, max = 60, where = "Blackrock Mountain" })

-- ============ Index ============
-- Acronym -> list of dungeon records (more than one = ambiguous).
-- User aliases (SavedVariables) are merged in at login and whenever
-- an alias is added: an alias REMOVES the acronym from every built-in
-- and points it at the chosen dungeon only - the user's word wins.

ns.ById = {}
ns.ByAcronym = {}

local function BuildIndex()
    ns.ById = {}
    ns.ByAcronym = {}
    for i = 1, #ns.Dungeons do
        local d = ns.Dungeons[i]
        ns.ById[d.id] = d
        for j = 1, #(d.acronyms or {}) do
            local acr = d.acronyms[j]:upper()
            ns.ByAcronym[acr] = ns.ByAcronym[acr] or {}
            ns.ByAcronym[acr][#ns.ByAcronym[acr] + 1] = d
        end
    end
    if ns.db and type(ns.db.aliases) == "table" then
        for acr, target in pairs(ns.db.aliases) do
            local d = ns.ById[target]
            if d then ns.ByAcronym[acr:upper()] = { d } end
        end
    end
end
ns.BuildIndex = BuildIndex
BuildIndex()

-- Resolve a chat token: returns a list of dungeon records (empty =
-- not a dungeon acronym; >1 = ambiguous), never nil.
local function Resolve(token)
    if type(token) ~= "string" then return {} end
    return ns.ByAcronym[token:upper()] or {}
end
ns.Resolve = Resolve
