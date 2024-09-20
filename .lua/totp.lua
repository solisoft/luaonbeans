-- TOTP verification

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

function getTimeCounter(offset)
    local current_time = os.time() + (offset or 0)
    return math.floor(current_time / 30)
end

local function byte_to_int(byte)
  return byte:byte()
end

local function dynamic_truncation(hash)
  -- Get the offset from the last byte
  local offset = byte_to_int(hash:sub(20, 20)) % 16 + 1

  -- Extract a 4-byte chunk starting at the calculated offset
  local part1 = byte_to_int(hash:sub(offset, offset)) * 2^24
  local part2 = byte_to_int(hash:sub(offset + 1, offset + 1)) * 2^16
  local part3 = byte_to_int(hash:sub(offset + 2, offset + 2)) * 2^8
  local part4 = byte_to_int(hash:sub(offset + 3, offset + 3))

  -- Combine these bytes into a single 32-bit integer
  local binary_code = part1 + part2 + part3 + part4

  -- Return the binary_code masked to a positive integer (ignoring the sign bit)
  return binary_code % 2^31
end

local function generateTOTP(secret, digits, time_counter)
  -- Decode the Base32 secret
  local key = DecodeBase32(secret, alphabet)
  -- Pack the time counter into a big-endian 64-bit integer
  local message = string.pack(">I8", time_counter)
  -- Generate SHA1 hash using the key and message
  local hash = GetCryptoHash("SHA1", message, key)
  -- Perform dynamic truncation on the hash
  local binary_code = dynamic_truncation(hash)
  -- Calculate the OTP by taking the modulus with 10^digits
  local otp = binary_code % (10 ^ digits)
  -- Format the OTP as a zero-padded string of the specified length
  return string.format("%0" .. digits .. "d", otp)
end

-- Function to validate a user-provided TOTP
function ValidateTOTP(secret, user_otp, digits)
  local time_steps = {-1, 0, 1}  -- Time windows to check (previous, current, next)

  for _, step in ipairs(time_steps) do
    local time_counter = getTimeCounter(step * 30)
    local generated_otp = generateTOTP(secret, digits, time_counter)

    if generated_otp == user_otp then
      return true
    end
  end

  return false  -- Invalid TOTP
end

function OTPAuth(secret, issuer, account)
  local base32_secret = EncodeBase32(secret, alphabet)
  return string.format(
    "otpauth://totp/%s:%s?secret=%s&issuer=%s&digits=6&period=30",
    issuer, account, base32_secret, issuer
  )
end

-- Example usage:
-- local secret = "JBSWY3DPEHPK3PXP"  -- Example Base32 secret (replace with your own)
-- local user_provided_otp = "123456"  -- OTP provided by the user (replace with actual input)
-- local is_valid = ValidateTOTP(secret, user_provided_otp, 6)
--
-- if is_valid then
--     print("The TOTP is valid!")
-- else
--     print("The TOTP is invalid!")
-- end
