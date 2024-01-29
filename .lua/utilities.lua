unix = require "unix"
etlua = require "etlua"
multipart = require "multipart"

require "utilities.table"
require "utilities.string"
require "utilities.multipart"
require "luaonbeans"

-- utilities

GenerateTempFilename = function()
  local filename = EncodeBase64(GetRandomBytes(32))
  filename = string.gsub(filename, "[\\/]", "")
  return "tmp/" .. filename
end

RunCommand = function(command)
  command = string.split(command)
  local prog = assert(unix.commandv(command[1]))

  local output = ""
  local reader, writer = assert(unix.pipe())
  if assert(unix.fork()) == 0 then
    unix.close(1)
    unix.dup(writer)
    unix.close(writer)
    unix.close(reader)
    unix.execve(prog, command, { 'PATH=/bin' })
    unix.exit(127)
  else
    unix.close(writer)
    while true do
      data, err = unix.read(reader)
      if data then
        if data ~= '' then
          output = output .. data
        else
          break
        end
      elseif err:errno() ~= unix.EINTR then
        Log(kLogWarn, tostring(err))
        break
      end
    end
    assert(unix.close(reader))
    unix.wait()
  end

  return output
end
