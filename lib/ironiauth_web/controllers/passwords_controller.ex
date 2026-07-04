defmodule IroniauthWeb.PasswordsController do
  use IroniauthWeb, :controller
  alias Ironiauth.Services.User.{ResetPasswordService, ForgotPasswordService}
  action_fallback IroniauthWeb.FallbackController

  def forgot_password(conn, %{"user" => %{"email" => email}}) do
    company = conn.assigns.current_company
    ForgotPasswordService.call(email, company)
    conn |> put_status(:ok) |> json(%{message: "If the email exists, a reset link was sent"})
  end

  def reset_password(conn, %{"token" => token, "user" => pass_attrs}) do
    service = ResetPasswordService.new(token, pass_attrs)
    case ResetPasswordService.call(service) do
      {:ok, _user} ->
        conn |> put_status(:ok) |> json(%{message: "Password updated successfully"})
      {:error, :reset_token_expired} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Reset token has expired"})
      {:error, :user_not_found} ->
        conn |> put_status(:not_found) |> json(%{error: "Invalid reset token"})
      {:error, :password_reset_failed} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Password reset failed"})
    end
  end
end
