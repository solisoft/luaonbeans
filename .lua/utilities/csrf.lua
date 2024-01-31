GenerateCSRFToken = function()
  if GetCookie("_authenticity_token") == nil then
    SetCookie(
      "_authenticity_token",
      EncodeBase64(GetRandomBytes(64)),
      {
        HttpOnly = true,
        MaxAge = 60 * 30,
        SameSite = "Strict"
      } -- available for 30 minutes
    )
  end
end

CheckCSRFToken = function()
  if GetMethod() == "POST" then
    assert(GetBodyParams()["authenticity_token"] == GetCookie("_authenticity_token"))
  end
end

AuthenticityTokenTag = function()
  return '<input type="hidden" name="authenticity_token" value="' .. GetCookie("_authenticity_token") .. '" />'
end
