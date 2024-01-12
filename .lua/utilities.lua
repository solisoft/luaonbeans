require "luaonbeans"
etlua = require "etlua"

-- Tables

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function table.merge(t1, t2)
  for k,v in pairs(t2) do
    t1[k] = v
  end
  return t1
end

-- Strings

function string.split(inputStr, sep)
  if sep == nil then
    sep = "%s" -- Default to whitespace
  end
  local t = {}
  for str in string.gmatch(inputStr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function string.to_slug(str)
  local slug = string.gsub(string.gsub(str,"[^ A-Za-z0-9]","-"),"[ ]+","-")
  return string.gsub(slug, "[-]+","-")
end