#!/usr/bin/env python3
"""LFG Lens gate: Lua parse + TOC cross-check + dictionary audit +
version consistency + harness.

Run: python3 tools/gate.py
The dictionary audit enforces the data honesty rules: the nine
Forever-new dungeons are present, their acronyms are all marked
proposed, NO level range is recorded for a new dungeon (none is
published), classic entries all carry ranges, and the three headline
collisions (ST, DM, BD) really do resolve to two dungeons each.
Proves parse/logic against a mock - in-game behaviour stays
Unverified until a live-client run.
"""
import pathlib
import re
import subprocess
import sys

from luaparser import ast

ROOT = pathlib.Path(__file__).resolve().parent.parent
ADDON = ROOT / "LFGLens"
TOC = "LFGLens_Camelot.toc"
EXPECTED_TOTAL = 33       # 9 new dungeons + 3 raids + 21 classic
EXPECTED_NEW_DUNGEONS = 9

VALIDATOR_LUA = r"""
function(ns)
  local bad = {}
  local function add(s) bad[#bad + 1] = s end
  local ids = {}
  local newDungeons, newRaids = 0, 0
  for i = 1, #ns.Dungeons do
    local d = ns.Dungeons[i]
    local id = (type(d.id) == "string" and d.id) or ("<entry " .. i .. ">")
    if type(d.id) ~= "string" or d.id == "" then add(id .. ": id missing") end
    if ids[d.id] then add(id .. ": duplicate id") end
    ids[d.id] = true
    if type(d.name) ~= "string" or d.name == "" then add(id .. ": name missing") end
    if d.kind ~= "dungeon" and d.kind ~= "raid" then add(id .. ": kind invalid") end
    if type(d.acronyms) ~= "table" or #d.acronyms < 1 then add(id .. ": no acronyms") end
    for j = 1, #(d.acronyms or {}) do
      if type(d.acronyms[j]) ~= "string" or d.acronyms[j] ~= d.acronyms[j]:upper() then
        add(id .. ": acronym not uppercase text")
      end
    end
    if d.new and d.kind == "dungeon" then
      newDungeons = newDungeons + 1
      if not d.proposed then add(id .. ": new-dungeon acronym must be marked proposed") end
      if d.min ~= nil or d.max ~= nil then
        add(id .. ": new dungeon carries a level range - none is published; do not invent one")
      end
    end
    if d.new and d.kind == "raid" then newRaids = newRaids + 1 end
    if not d.new and (type(d.min) ~= "number" or type(d.max) ~= "number") then
      add(id .. ": classic entry without its published level range")
    end
  end
  if #ns.Dungeons ~= TOTAL then add("dungeon count " .. #ns.Dungeons .. " != " .. TOTAL) end
  if newDungeons ~= NEWD then add("new dungeons " .. newDungeons .. " != " .. NEWD) end
  if newRaids ~= 2 then add("new raids " .. newRaids .. " != 2") end
  for _, acr in ipairs({ "ST", "DM", "BD" }) do
    local hits = ns.Resolve(acr)
    if #hits ~= 2 then add("collision " .. acr .. " resolves to " .. #hits .. ", want 2") end
  end
  return bad
end
"""


def schema_failures():
    try:
        import lupa
    except ImportError:
        return ["lupa not available for schema validation"]
    lua = lupa.LuaRuntime()
    lua.globals().TOTAL = EXPECTED_TOTAL
    lua.globals().NEWD = EXPECTED_NEW_DUNGEONS
    validate = lua.eval(VALIDATOR_LUA)
    ns = lua.table()
    ns.Dungeons = lua.table()
    chunk = lua.compile((ADDON / "Data.lua").read_text())
    chunk("LFGLens", ns)
    bad = validate(ns)
    problems = [bad[i] for i in range(1, len(bad) + 1)]
    print(f"schema: {len(ns.Dungeons)} dungeons, {len(problems)} problem(s)")
    return [f"schema: {p}" for p in problems]


def main():
    failures = []
    lua_files = sorted(ADDON.glob("*.lua"))
    for path in lua_files:
        try:
            ast.parse(path.read_text())
            print(f"parse ok: {path.name}")
        except Exception as exc:
            failures.append(f"parse FAIL {path.name}: {exc}")
    lines = (ADDON / TOC).read_text().splitlines()
    listed = [ln.strip() for ln in lines if ln.strip().endswith(".lua")]
    iface = [ln for ln in lines if ln.startswith("## Interface:")]
    print(f"{TOC}: interface {iface} files {listed}")
    if iface != ["## Interface: 16001"]:
        failures.append(f"{TOC} interface is {iface}, want 16001 (Forever only)")
    for name in listed:
        if not (ADDON / name).exists():
            failures.append(f"{TOC} lists missing file {name}")
    for path in lua_files:
        if path.name not in listed:
            failures.append(f"{path.name} exists but is not in the TOC")
    # UI rule (Forever): SetBackdrop only in the UI file, which must
    # create its frame with BackdropTemplate.
    for path in lua_files:
        text = path.read_text()
        if "SetBackdrop(" in text and path.name != "UI.lua":
            failures.append(f"{path.name} calls SetBackdrop outside UI.lua")
    ui_text = (ADDON / "UI.lua").read_text()
    if "SetBackdrop(" in ui_text and "BackdropTemplate" not in ui_text:
        failures.append("UI.lua calls SetBackdrop without BackdropTemplate")
    failures += schema_failures()
    versions = {}
    m = re.search(r"^## Version:\s*(\S+)", (ADDON / TOC).read_text(), re.M)
    versions[TOC] = m.group(1) if m else None
    m = re.search(r'ns\.VERSION = "([^"]+)"', (ADDON / "Core.lua").read_text())
    versions["Core.lua"] = m.group(1) if m else None
    m = re.search(r'^VERSION = "([^"]+)"',
                  (ROOT / "tools" / "package.py").read_text(), re.M)
    versions["package.py"] = m.group(1) if m else None
    if len(set(versions.values())) == 1 and None not in versions.values():
        print(f"version consistency: {versions['Core.lua']} in all 3 places")
    else:
        failures.append(f"version mismatch: {versions}")
    proc = subprocess.run(
        [sys.executable, str(ROOT / "tools" / "harness.py")],
        capture_output=True, text=True)
    print(proc.stdout)
    if proc.returncode != 0:
        failures.append("harness FAIL")
        print(proc.stderr)
    if failures:
        print("GATE: FAIL")
        for f in failures:
            print(" -", f)
        sys.exit(1)
    print("GATE: PASS (parse + toc + dictionary audit + version + harness)")


if __name__ == "__main__":
    main()
