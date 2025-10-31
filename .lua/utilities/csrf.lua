CheckCSRFToken = function()
  if GetMethod() == "POST" then
    local crypted_token = EncodeBase64(GetCryptoHash("SHA256", GetBodyParams()["authenticity_token"], ENV['SECRET_KEY']))
    assert(crypted_token == GetCookie("_authenticity_token"), "Bad authenticity_token")
  end
end

AuthenticityTokenTag = function()
  local CSRFToken = EncodeBase64(GetRandomBytes(64))
  SetCookie(
    "_authenticity_token",
    EncodeBase64(GetCryptoHash("SHA256", CSRFToken, ENV['SECRET_KEY'])),
    {
      HttpOnly = true,
      MaxAge = 60 * 30,
      SameSite = "Strict",
      Path="/"
    } -- available for 30 minutes
  )
  return '<input type="hidden" name="authenticity_token" value="' .. CSRFToken .. '" />'
end
