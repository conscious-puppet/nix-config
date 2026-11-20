-- The app's custom theme IDs.
--
-- The app keeps a theme's colors, and the ID that selects it, in its own
-- preferences. An imported theme gets an ID such as
-- custom-40CF43D3-B5C9-44F0-A51A-BC04387C2FD0, made fresh on each Mac, so a
-- configuration that hardcoded one would select the theme on the Mac that
-- imported it and nothing on any other. The name the app gives a theme (the
-- imported file's basename, without its extension) is the same everywhere, so
-- the settings name themes and this module looks up this Mac's ID for a name.
--
-- Only reading is involved: the app is the one thing that can add a theme, by
-- importing solarized-dark.toml as that file explains. Nothing here changes
-- the app's preferences, and a missing theme only makes its setting skip.

local M = {}

local DOMAIN = "com.superlogical.rex"
-- The app's custom themes, a JSON array stored as a preferences data value.
local THEMES_KEY = "Workspace.customThemes"
local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Run a command and return what it printed, or nil and why it failed.
local function output(argv)
  local res, err = rex.exec(argv)
  if res == nil then
    return nil, err
  end
  if not res.ok then
    local why = res.stderr:gsub("%s+$", "")
    return nil, why ~= "" and why or ("exit status " .. res.code)
  end
  return res.stdout
end

-- Join many short pieces into one string. Lua 5.1 in Rex raises "registry
-- overflow" when table.concat takes many thousands of them at once, so join in
-- chunks.
local function join(pieces)
  local parts = {}
  local size = 512
  for i = 1, #pieces, size do
    parts[#parts + 1] = table.concat(pieces, "", i, math.min(i + size - 1, #pieces))
  end
  return table.concat(parts)
end

local function decode_base64(text)
  local digit = {}
  for i = 1, #ALPHABET do
    digit[ALPHABET:sub(i, i)] = i - 1
  end

  local bytes, acc, bits = {}, 0, 0
  for i = 1, #text do
    local char = text:sub(i, i)
    if char == "=" then
      break
    end
    local value = digit[char]
    if value ~= nil then
      acc = acc * 64 + value
      bits = bits + 6
      while bits >= 8 do
        bits = bits - 8
        bytes[#bytes + 1] = string.char(math.floor(acc / 2 ^ bits) % 256)
      end
      acc = acc % 2 ^ bits
    end
  end
  return join(bytes)
end

-- This Mac's custom themes, by the name the app shows for each.
local function custom_themes()
  local plist = os.tmpname()

  local exported, err = output({ "/usr/bin/defaults", "export", DOMAIN, plist })
  if exported == nil then
    os.remove(plist)
    return nil, err
  end

  -- plutil prints a data value as base64, which here is the JSON we want. A
  -- domain without the key means no custom theme has been imported yet.
  local encoded
  encoded, err = output({ "/usr/bin/plutil", "-extract", THEMES_KEY:gsub("%.", "\\."), "raw", "-o", "-", plist })
  os.remove(plist)
  if encoded == nil then
    return {}
  end

  local themes, decode_err = rex.json.decode(decode_base64(encoded:gsub("%s+", "")))
  if themes == nil then
    return nil, decode_err
  end

  local by_name = {}
  for _, theme in ipairs(themes) do
    if type(theme) == "table" and theme.name ~= nil and theme.id ~= nil then
      by_name[theme.name] = theme.id
    end
  end
  return by_name
end

-- The ID that selects the custom theme called name on this Mac, or nil and
-- why there is no such theme.
function M.id(name)
  local themes, err = custom_themes()
  if themes == nil then
    return nil, err
  end

  local id = themes[name]
  if id == nil then
    return nil, ("no custom theme %q on this Mac; import %s.toml from Settings > Themes"):format(name, name)
  end
  return id
end

return M
