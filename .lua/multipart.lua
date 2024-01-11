-- Fork from fullmoon code --
--[[-- multipart parsing --]]--

local patts = {}
local function getParameter(header, name)
  local function optignorecase(s)
    if not patts[s] then
      patts[s] = (";%s*"
        ..s:gsub("%w", function(s) return ("[%s%s]"):format(s:upper(), s:lower()) end)
        ..[[=["']?([^;"']*)["']?]])
    end
    return patts[s]
  end
  return header:match(optignorecase(name))
end

local CRLF, TAIL = "\r\n", "--"
local CRLFlen = #CRLF
local MULTIVAL = "%[%]$"

local function argerror(cond, narg, extramsg, name)
  if cond then return cond end
  name = name or debug.getinfo(2, "n").name or "?"
  local msg = ("bad argument #%d to %s%s"):format(narg, name, extramsg and " "..extramsg or  "")
  return error(msg, 3)
end

local function parseMultipart(body, ctype)
  argerror(type(ctype) == "string", 2, "(string expected)")
  local parts = {
    boundary = getParameter(ctype, "boundary"),
    start = getParameter(ctype, "start"),
  }
  local boundary = "--"..argerror(parts.boundary, 2, "(boundary expected in Content-Type)")
  local bol, eol, eob = 1
  while true do
    repeat
      eol, eob = string.find(body, boundary, bol, true)
      if not eol then return nil, "missing expected boundary at position "..bol end
    until eol == 1 or eol > CRLFlen and body:sub(eol-CRLFlen, eol-1) == CRLF
    if eol > CRLFlen then eol = eol - CRLFlen end
    local headers, name, filename = {}
    if bol > 1 then
      -- find the header (if any)
      if string.sub(body, bol, bol+CRLFlen-1) == CRLF then -- no headers
        bol = bol + CRLFlen
      else -- headers
        -- find the end of headers (CRLF+CRLF)
        local boh, eoh = 1, string.find(body, CRLF..CRLF, bol, true)
        if not eoh then return nil, "missing expected end of headers at position "..bol end
        -- join multi-line header values back if present
        local head = string.sub(body, bol, eoh+1):gsub(CRLF.."%s+", " ")
        while (string.find(head, CRLF, boh, true) or 0) > boh do
          local p, e, header, value = head:find("([^:]+)%s*:%s*(.-)%s*\r\n", boh)
          if p ~= boh then return nil, "invalid header syntax at position "..bol+boh end
          header = header:lower()
          if header == "content-disposition" then
            name = getParameter(value, "name")
            filename = getParameter(value, "filename")
          end
          headers[header] = value
          boh = e + 1
        end
        bol = eoh + CRLFlen*2
      end
      -- epilogue is processed, but not returned
      local ct = headers["content-type"]
      local b, err = string.sub(body, bol, eol-1)
      if ct and ct:lower():find("^multipart/") then
        b, err = parseMultipart(b, ct) -- handle multipart/* recursively
        if not b then return b, err end
      end
      local first = parts.start and parts.start == headers["content-id"] and 1
      local v = {name = name, headers = headers, filename = filename, data = b}
      table.insert(parts, first or #parts+1, v)
      if name then
        if string.find(name, MULTIVAL) then
          parts[name] = parts[name] or {}
          table.insert(parts[name], first or #parts[name]+1, v)
        else
          parts[name] = parts[name] or v
        end
      end
    end
    local tail = body:sub(eob+1, eob+#TAIL)
    -- check if the encapsulation or regular boundary is present
    if tail == TAIL then break end
    if tail ~= CRLF then return nil, "missing closing boundary at position "..eol end
    bol = eob + #tail + 1
  end
  return parts
end
