local app = {
	upload = function()
		token = JWT.DecodeAndVerify(Params.token, ENV['JWT_SECRET'])
		-- token.payload.iat must be less than 3600 seconds ago
		if token and ((GetDate() // 1) - token.payload.iat < 3600) then
			if Params.file then
				local uuid = UuidV7()

				Adb.CreateDocument("uploads", {
					uuid = uuid,
					ext = Params.file.ext,
					filename = Params.file.filename,
					content_type = Params.file.content_type,
					size = Params.file.size,
					object_id = Params.collection .. "/" .. Params.key,
					field = Params.field,
					created_at = os.time(),
					updated_at = os.time(),
				})

				WriteJSON({
					uuid = uuid
				})

				Barf("uploads/" .. uuid .. "." .. Params.file.ext, Params.file.content)
				unix.symlink("uploads/" .. uuid .. "." .. Params.file.ext, "uploads/" .. uuid)
			end
		else
			SetStatus(401)
			WriteJSON({
				message = "Invalid token"
			})
		end
	end,

	original_image = function()
		if ServeAsset("uploads/" .. Params.uuid .. "." .. Params.format) then
			return
		else
			local original_filename = unix.readlink("uploads/" .. Params.uuid)
			local converted_filename = original_filename:split(".")[1] .. "." .. Params.format
			RunCommand("vips copy " .. original_filename .. " " .. converted_filename)
			ServeAsset(converted_filename)
		end
	end,

	resized_image_x = function()
		Params.width = tonumber(Params.width) > 1600 and 1600 or Params.width
		if ServeAsset("uploads/" .. Params.uuid .. "-" .. Params.width.. "." .. Params.format) then
			return
		else
			local original_filename = unix.readlink("uploads/" .. Params.uuid)
			local converted_filename = original_filename:split(".")[1] .. "-" .. Params.width .. "." .. Params.format
			RunCommand("vips thumbnail " .. original_filename .. " " .. converted_filename .. " " .. Params.width)
			ServeAsset(converted_filename)
		end
	end,

	resized_image_x_y = function()
		Params.width = tonumber(Params.width) > 1600 and 1600 or Params.width
		Params.height = tonumber(Params.height) > 1600 and 1600 or Params.height
		if ServeAsset("uploads/" .. Params.uuid .. "-" .. Params.width .. "x" .. Params.height .. "." .. Params.format) then
			return
		else
			local original_filename = unix.readlink("uploads/" .. Params.uuid)
			local converted_filename = original_filename:split(".")[1] .. "-" .. Params.width .. "x" .. Params.height .. "." .. Params.format
			RunCommand("vips thumbnail " .. original_filename .. " " .. converted_filename .. " " .. Params.width .. " --height " .. Params.height .. " --crop centre")
			ServeAsset(converted_filename)
		end
	end
}

return HandleController(app)
