CSRFToken = EncodeBase64(GetRandomBytes(64))

CheckCSRFToken = function()
  if GetMethod() == "POST" then
    local crypted_token = EncodeBase64(GetCryptoHash("SHA256", GetBodyParams()["authenticity_token"], ENV['SECRET_KEY']))
    print(GetBodyParams()["authenticity_token"],crypted_token, GetCookie("_authenticity_token"))
    assert(crypted_token == GetCookie("_authenticity_token"))
  end
end

AuthenticityTokenTag = function()
  if GetCookie("_authenticity_token") == nil then
    CSRFToken = EncodeBase64(GetRandomBytes(64))
    print(CSRFToken, EncodeBase64(GetCryptoHash("SHA256", CSRFToken, ENV['SECRET_KEY'])))
    SetCookie(
      "_authenticity_token",
      EncodeBase64(GetCryptoHash("SHA256", CSRFToken, ENV['SECRET_KEY'])),
      {
        HttpOnly = true,
        MaxAge = 60 * 30,
        SameSite = "Strict"
      } -- available for 30 minutes
    )
  end
  return '<input type="hidden" name="authenticity_token" value="' .. CSRFToken .. '" />'
end
