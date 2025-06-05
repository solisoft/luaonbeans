local _INFO = {
	_VERSION = "jwt.lua 1.0.4",
	_URL = "github.com/w13b3/redbean-jwt",
	_DESCRIPTION = "JSON Web Token for redbean",
	_LICENSE = [[
			Copyright 2022 w13b3

			Permission to use, copy, modify, and/or distribute this software for
			any purpose with or without fee is hereby granted, provided that the
			above copyright notice and this permission notice appear in all copies.

			THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
			WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
			WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
			AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
			DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
			PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
			TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
			PERFORMANCE OF THIS SOFTWARE.
	]],
}

local re = require("re")	-- redbean built-in regex module


---Wrapper to catch errors
---@private
---@param func function Function to catch errors from
---@param defaultReturn any Optional set what to return on failure
---@return any On success
---@return nil, string When error occurs
local function CatchError(func, defaultReturn)
	assert(type(func) == "function",
					("Bad argument #1 to 'CatchError' (function expected, got %s)"):format(type(func)))
	-- wrapper function
	return function(...)
			-- pack result into a table, result[1] is the boolean from `pcall`
			local result = { pcall(func, ...) }
			if result[1] then
					-- unpack and discard the `pcall` bool
					return select(2, table.unpack(result))
			else -- `pcall` received error
					return defaultReturn, result[2]
			end
	end
end


local Common = {}
Common.__index = Common

---Base64URL is a modification of the main Base64 standard
---@private
---@param str string String to encode in Base64URL
---@return string
function Common.EncodeBase64URL(str)
	-- rfc7515#appendix-C
	assert(type(str) == "string", ("EncodeBase64URL expects a string, received: %s"):format(type(str)))
	local subsitute = { ["/"] = "_", ["+"] = "-", ["="] = "" }	-- also remove the `=` padding
	local result = EncodeBase64(str)	-- redbean function
	for key, val in pairs(subsitute) do
			result = (result):gsub(key, val)
	end
	return result
end

---Base64URL is a modification of the main Base64 standard
---@private
---@param str string Base64URL encoded string
---@return string
function Common.DecodeBase64URL(str)
	-- rfc7515#appendix-C
	assert(type(str) == "string", ("DecodeBase64URL expects a string, received: %s"):format(type(str)))
	local subsitute = { ["_"] = "/", ["-"] = "+" }
	for key, val in pairs(subsitute) do
			str = (str):gsub(key, val)
	end
	-- has not seen any errors due to the lack of padding
	return DecodeBase64(str)	-- redbean function
end

---Encode a segment to a base64URL encoded string
---@private
---@param segmentObject JsonValue Commonly a table or a string
---@return string Base64URL encoded string
function Common.EncodeSegment(segmentObject)
	local encodedSegment = assert(EncodeJson(segmentObject, { pretty = false }))	-- encode to string
	return Common.EncodeBase64URL(encodedSegment)
end

---Decode a base64URL encoded string to the original segment
---@private
---@param base64Segment string Base64URL encoded string
---@return JsonValue
function Common.DecodeSegment(base64Segment)
	assert(type(base64Segment) == "string", ("DecodeSegment expects a string, received: %s"):format(type(base64Segment)))
	local decodedSegment = Common.DecodeBase64URL(base64Segment)
	-- ternary: if string has length larger than 0 otherwise empty JSON string
	decodedSegment = (#decodedSegment > 0) and decodedSegment or "[]"
	return assert(DecodeJson(decodedSegment))	-- decode the segment, not necessary a table
end


-- JWA	- datatracker.ietf.org/doc/html/rfc7518	- archive.ph/04oex
local JWA = {}
JWA.__index = JWA

JWA.default = "HS256"

JWA.supported = {
	-- These algorithms are compatible with the standard
	"none", "HS256", "HS384", "HS512",
	-- These algorithms are incompatible with the standard, but GetCryptoHash can use these
	"BLAKE2B256", "MD5",	"SHA1",	"SHA224",	"SHA256",	"SHA384", "SHA512"
}

-- algorithms lookup table
JWA.lookup = {
	["NONE"]			 = "none",	 -- required
	["HS256"]			= "SHA256", -- required algorithm - rfc7518#section-3.1
	["HS384"]			= "SHA384",
	["HS512"]			= "SHA512",
	-- incompatible with JWT
	["BLAKE2B256"] = "BLAKE2B256",
	["MD5"]				= "MD5",
	["SHA1"]			 = "SHA1",
	["SHA224"]		 = "SHA224",
	["SHA256"]		 = "SHA256",
	["SHA384"]		 = "SHA384",
	["SHA512"]		 = "SHA512",
}

---Check the signature by hashing the message with multiple algorithms
---@private
---@param message string The payload that was encrypted
---@param signature string The received decoded signature
---@param key string The secret which was used to hash the payload
---@param algorithms table The allowed algorithms
---@return boolean, string if the hashed message matches the signature, returned string is the algorithm used
---@return nil, string when no match is found
function JWA.CheckHash(message, signature, key, algorithms)
	for _, alg in pairs(algorithms) do
			-- pcall used so GetCryptoHash doesn't fail if it receive a hash-type it can't use
			local bool, hash = pcall(GetCryptoHash, JWA.lookup[string.upper(alg)], message, key)
			-- also check "none"	-	rfc7518#section-3.6
			if (bool and hash == signature) or (alg == "none" and signature == "") then
					return true, alg
			end
	end
	return nil, string.format("The signature '%s' does not match the hashed message. Used algorithms: %s",
					EncodeLua(signature), EncodeLua(algorithms))
end


-- JWS	- datatracker.ietf.org/doc/html/rfc7515	- archive.ph/a381l
local JWS = {}	-- main table
JWS.__index = JWS

-- JWS can have 2 or up to 3 segments
-- unsecured signatures are missing the 3rd segment but have can have a trailing dot '.' according rfc7519#section-6.1
JWS.splitTokenRegex = assert(re.compile([[([a-zA-Z0-9_-]+)\.([a-zA-Z0-9_-]+)\.?([a-zA-Z0-9_-]+)?]]))

---Create a basic table
---@public
---@return table A default JWS table
function JWS.BasicTable()
	return {
			["header"] = {
					["alg"] = JWA.default
			},
			["payload"] = {
					["iat"] = os.time()
			}
	}
end

---See JWT.Encode
---@private
function JWS.Encode(jwtTable, key, algorithm)
	-- check given parameters
	assert(type(jwtTable) == "table", "Parameter: 'jwtTable' not of type table")
	assert(type(jwtTable.header) == "table", "Header in the parameter: 'jwtTable' not of type table")
	assert(type(jwtTable.payload) == "table", "Payload in the parameter: 'jwtTable' not of type table")

	if key ~= nil then
			assert(type(key) == "string", "Parameter: 'key' is not of type string")
	else
			-- key can be nil, but it defeats the purpose of JWS
			Log(kLogWarn, "Given key is of value: nil")
	end

	-- override alg-value or fallback to default	(alg > header.alg > JWA.default)
	algorithm = algorithm or jwtTable.header.alg or JWA.default
	assert((algorithm ~= nil), "Given or received algorithm is not supported")

	-- override the algorithm in the header
	jwtTable.header.alg = algorithm

	-- combine header and payload into body
	local message = ("%s.%s"):format(Common.EncodeSegment(jwtTable.header), Common.EncodeSegment(jwtTable.payload))

	local hash64 = ""
	if algorithm ~= "none" then
			-- sign body with secret and add this signature to the body
			local hash = GetCryptoHash(JWA.lookup[algorithm], message, key)
			hash64 = Common.EncodeBase64URL(hash)
	end

	-- create the JWS string
	local result = ("%s.%s"):format(message, hash64)
	return result
end

---See JWT.VerifyTable
---@private
function JWS.Decode(data)
	-- check given parameters
	assert(type(data) == "string", "Parameter: 'data' not of type string")

	-- split the JWS on its dot's
	local match, b64header, b64payload, b64signature = JWS.splitTokenRegex:search(data)
	assert((match ~= nil), "Parameter: 'data' has an unexpected format")

	-- decode the splitted parts
	local header = Common.DecodeSegment(b64header)
	local payload = Common.DecodeSegment(b64payload)
	local signature = Common.DecodeBase64URL(b64signature)
	-- reflect payload verification with the NotVerified code
	local result = {
			["jwtVerified"] = false,	-- this decoded JWS is not verified

			-- tables
			["header"]		= header,
			["payload"]	 = payload,
			["signature"] = signature,

			-- used in verify
			["b64header"]		= b64header,
			["b64payload"]	 = b64payload,
			["b64signature"] = b64signature
	}
	return result
end

---See JWT.VerifyTable
---@private
function JWS.VerifyTable(jwtTable, key, algorithms)
	-- check given parameters
	assert(type(jwtTable) == "table", "Parameter 'jwtTable' not of type table")
	assert(type(key) == "string", "Parameter: 'key' not of type string")
	-- check jwtTable content
	assert(type(jwtTable.signature) == "string", "Parameter: 'jwtTable' does not contain a signature string")
	assert(type(jwtTable.header) == "table", "Parameter: 'jwtTable' does not contain a header table")
	assert(jwtTable.payload ~= nil, "Parameter: 'jwtTable' does not contain a payload")

	-- if no algorithms are specified, fall back onto the supported algorithms
	algorithms = algorithms or JWA.supported
	if type(algorithms) == "string" then algorithms = { algorithms } end
	assert(type(algorithms) == "table", "Given parameter: 'algorithms' not of type table")

	-- define the base64 header and payload
	local b64header = jwtTable.b64header or Common.EncodeSegment(jwtTable.header)
	local b64payload = jwtTable.b64payload or Common.EncodeSegment(jwtTable.payload)

	-- verify the signature
	local message = ("%s.%s"):format(b64header, b64payload)
	assert(JWA.CheckHash(message, jwtTable.signature, key, algorithms))

	-- set verified to true, because the JWS is now verified
	jwtTable.jwtVerified = true
	return jwtTable
end

---See JWT.DecodeAndVerify
---@private
function JWS.DecodeAndVerify(data, key, algorithms)
	-- check given parameters
	assert(type(key) == "string", "Parameter: 'key' not of type string")
	assert(type(data) == "string", "Parameter: 'data' not of type string")

	-- decode the data
	local jwtTable = assert(JWS.Decode(data))

	-- verify the decoded table content
	jwtTable = assert(JWS.VerifyTable(jwtTable, key, algorithms))
	-- return verified table
	return jwtTable
end


-- JWT	- datatracker.ietf.org/doc/html/rfc7519	- archive.ph/KDWdO
local JWT = {}	-- main table
JWT.__index = JWT

---Encode JSON that has header and payload keys
---@public
---@param jwtTable table Header and payload of the JWT in a table
---@param key string Secret of the server
---@param algorithm string If given it overrides the alg-value given in the JWT-header
---@return string JWT string
---@return nil, string When error occurs
function JWT.Encode(jwtTable, key, algorithm)
	return CatchError(JWS.Encode)(jwtTable, key, algorithm)
end

---Decodes the given JWT string to a table
---@public
---@param data string JWT string
---@return table Table with data from the decoded JWT
---@return nil, string When error occurs
function JWT.Decode(data)
	return CatchError(JWS.Decode)(data)
end

---Verify signature of a decoded JWT table
---@public
---@param jwtTable table Preferably received from `Decode` function
---@param key string Secret of the server
---@param algorithms table A Table algorithm strings that are accepted to use
---@return table Table with JWT parts
---@return nil, string When error occurs
function JWT.VerifyTable(jwtTable, key, algorithms)
	return CatchError(JWS.VerifyTable)(jwtTable, key, algorithms)
end

---Decode the JWT and verify the signature
---@public
---@param data string JWT string
---@param key string Secret of the server
---@param algorithms table A Table algorithm strings that are accepted to use
---@return table Table with data from the decoded JWT
---@return nil, string When error occurs
function JWT.DecodeAndVerify(data, key, algorithms)
	return CatchError(JWS.DecodeAndVerify)(data, key, algorithms)
end

---See JWT.SetCookieToken
---@private
local function SetCookieToken(jwtTable, key, alg, cookieOptions)
	-- set default cookieOptions
	cookieOptions = cookieOptions or {}
	-- create and set the token in a Cookie
	local token = assert(JWT.Encode(jwtTable, key, alg))
	SetCookie(
			cookieOptions.name or "access_token",		-- name
			token,																	 -- token
			cookieOptions														-- options
	)
	return true
end

---Set a cookie with a token
---@public
---@param jwtTable table Header and payload of the JWT in a table
---@param key string Secret of the server
---@param algorithm string If given it overrides the alg-value given in the JWT-header
---@param cookieOptions table Optional cookie options
---@return boolean True if no error has occurred
---@return nil, string When error occurs
function JWT.SetCookieToken(jwtTable, key, algorithm, cookieOptions)
	return CatchError(SetCookieToken)(jwtTable, key, algorithm, cookieOptions)
end

---See JWT.VerifyCookieToken
---@private
local function VerifyCookieToken(key, data, algorithms, cookieName)
	-- check given parameters
	if type(data) ~= "string" then
			data = GetCookie(cookieName or "access_token")
			-- assure data is not nil
			assert(data ~= nil, "Could not read the cookie data")
	end
	-- decode, verify and return data
	return assert(JWT.DecodeAndVerify(data, key, algorithms))
end

---Verify a cookie containing the token
---@public
---@param key string Secret of the server
---@param data string Optional verifies given data instead of cookie
---@param algorithms table A Table algorithm strings that are accepted to use
---@param cookieName table Optional custom cookie name
---@return table Table with data from the decoded JWT
---@return nil, string When error occurs
function JWT.VerifyCookieToken(key, data, algorithms, cookieName)
	return CatchError(VerifyCookieToken)(key, data, algorithms, cookieName)
end

---See JWT.SetHeaderToken
---@private
local function SetHeaderToken(jwtTable, key, algorithm)
	local token = assert(JWT.Encode(table.unpack(jwtTable, key, algorithm)))
	SetHeader("Authorization", string.format("Bearer %s", token))
	return true
end

---Set an Authorization header with a JWT Bearer token
---@public
---@param jwtTable table Header and payload of the JWT in a table
---@param key string Secret of the server
---@param algorithm string If given it overrides the alg-value given in the JWT-header
---@return boolean True if no error has occurred
---@return nil, string When error occurs
function JWT.SetHeaderToken(jwtTable, key, algorithm)
	return CatchError(SetHeaderToken)(jwtTable, key, algorithm)
end

---See JWT.VerifyHeaderToken
---@private
local function VerifyHeaderToken(key, data, algorithms)
	-- check given parameters
	if type(data) ~= "string" then
			data = GetHeader("Authorization")
			-- assure data is not nil
			assert(data ~= nil, "Could not read the cookie data")
	end
	-- decode, verify and return data
	return assert(JWT.DecodeAndVerify(data, key, algorithms))
end

---Verify the Authorization header containing a JWT Bearer token
---@public
---@param key string Secret of the server
---@param data string Optional verifies given data instead of header
---@param algorithms table A Table algorithm strings that are accepted to use
---@return table Table with data from the decoded JWT
---@return nil, string When error occurs
function JWT.VerifyHeaderToken(key, data, algorithms)
	return CatchError(VerifyHeaderToken)(key, data, algorithms)
end


JWT._INFO = _INFO
JWT._Common = Common
JWT._JWS = JWS
JWT._JWA = JWA

return JWT