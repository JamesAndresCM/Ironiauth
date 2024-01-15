defmodule IroniauthWeb.Plugs.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline, otp_app: :ironiauth,
  module: Ironiauth.Guardian,
  error_handler: Ironiauth.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end