-- Loads every civ's style table from civs/<civ>.lua (each researched in docs/art/culture/<civ>.md).
-- A civ file returns { <role> = unit style, ..., _buildings = building style, _palette = colours }.
local S = {}
local CIV_IDS = { "britons", "byzantines", "chinese", "franks", "japanese", "mongols", "ottomans", "saracens",
                  "teutons", "vikings" }
for _, id in ipairs(CIV_IDS) do
  local path = GEN_ROOT .. "/civs/" .. id .. ".lua"
  if app.fs.isFile(path) then S[id] = dofile(path) end
end
return S
