defmodule IroniauthWeb.PasswordsController do
  use IroniauthWeb, :controller
  alias Ironiauth.Services.User.{ResetPasswordService, ForgotPasswordService}
  action_fallback IroniauthWeb.FallbackController

  def forgot_password(conn, %{"user" => user_params} = params) do
    email = Map.get(user_params, "email", "")
    ForgotPasswordService.call(email)
  end

  def reset_password(conn, %{"token" => token, "user" => pass_attrs}) do
    service = ResetPasswordService.new(token, pass_attrs)
    ResetPasswordService.call(service)
  end
end
