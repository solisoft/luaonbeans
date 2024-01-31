Unix = require "unix"
Re = require "re"
Etlua = require "etlua"
Multipart = require "multipart"

require "utilities.table"
require "utilities.string"
require "utilities.multipart"
require "utilities.csrf"
require "luaonbeans"

GenerateTempFilename = function()
  local filename = EncodeBase64(GetRandomBytes(32))
  filename = string.gsub(filename, "[\\/]", "")
  return "tmp/" .. filename
end

RunCommand = function(command)
  command = string.split(command)
  local prog = assert(Unix.commandv(command[1]))

  local output = ""
  local reader, writer = assert(Unix.pipe())
  if assert(Unix.fork()) == 0 then
    Unix.close(1)
    Unix.dup(writer)
    Unix.close(writer)
    Unix.close(reader)
    Unix.execve(prog, command, { 'PATH=/bin' })
    Unix.exit(127)
  else
    Unix.close(writer)
    while true do
      local data, err = Unix.read(reader)
      if data then
        if data ~= '' then
          output = output .. data
        else
          break
        end
      elseif err:errno() ~= Unix.EINTR then
        Log(kLogWarn, tostring(err))
        break
      end
    end
    assert(Unix.close(reader))
    Unix.wait()
  end

  return output
end
