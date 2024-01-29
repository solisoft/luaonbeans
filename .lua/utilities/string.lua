-- Strings

string.split = function(inputStr, sep)
  sep = sep or "%s"
  local t = {}
  for str in string.gmatch(inputStr, "([^" .. sep .. "]+)") do
    table.insert(t, str)
  end
  return t
end

string.to_slug = function(str)
  local slug = string.gsub(string.gsub(str, "[^ A-Za-z0-9]", "-"), "[ ]+", "-")
  slug = string.gsub(slug, "[-]+", "-")
  slug = string.gsub(slug, "[-]+$", "")

  return string.lower(slug)
end

string.strip = function(str)
  return (str:gsub("^%s*(.-)%s*$", "%1"))
end

local vowels = { "a", "e", "i", "o", "u" }

local function pluralizeWord(word)
  if word:match("f$") or word:match("fe$") then
    word = word:gsub("f$", "ves"):gsub("fe$", "ves")
  elseif word:match("ch$") or word:match("sh$") or word:match("s$") or word:match("x$") or word:match("z$") or
      (not table.contains(vowels, word:sub(-2, -2)) and word:match("o$")) then
    word = word .. "es"
  elseif not table.contains(vowels, word:sub(-2, -2)) and word:match("y$") then
    word = word:gsub("y$", "ies")
  else
    word = word .. "s"
  end
  return word
end

Pluralize = function(str, deepPluralize)
  if deepPluralize then
    local newStr = ""
    for word in str:gmatch("%S+") do
      newStr = newStr .. pluralizeWord(word) .. " "
    end
    return newStr:sub(1, -1)
  else
    return pluralizeWord(str)
  end
end

local function singularizeWord(word)
  if word:match("ives$") then
    word = word:gsub("ives$", "ife")
  elseif word:match("ves$") then
    word = word:gsub("ves$", "f")
  elseif word:match("shes$") or word:match("ches$") or word:match("ses$") or word:match("xes$") or word:match("zes$") or
      (not table.contains(vowels, word:sub(-4, -4)) and word:match("oes$")) then
    word = word:gsub("es$", "")
  elseif not table.contains(vowels, word:sub(-4, -4)) and word:match("ies$") then
    word = word:gsub("ies$", "y")
  elseif word:match("s$") and word:match("ss$") == nil then
    word = word:sub(1, -2)
  end
  return word
end

Singularize = function(str, deepSingularize)
  if deepSingularize then
    local newStr = ""
    for word in str:gmatch("%S+") do
      newStr = newStr .. singularizeWord(word) .. " "
    end
    return newStr:sub(1, -1)
  else
    return singularizeWord(str)
  end
end

Capitalize = function(str)
  return (string.gsub(str, '^%l', string.upper))
end

Camelize = function(str)
  return Capitalize(string.gsub(str, '%W+(%w+)', Capitalize))
end
