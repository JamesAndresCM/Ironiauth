defmodule IroniauthWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use IroniauthWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: IroniauthWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(html: IroniauthWeb.ErrorHTML, json: IroniauthWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Login error"})
  end

  def call(conn, {:ok, user}) do
    conn
    |> json(%{msg: "Your password has been reset. Sign in below with your new password."})
    |> halt()
  end

  def call(conn, {:ok, :send_passwd_mailer}) do
    conn
    |> json(%{msg: "Email sent with password reset instructions"})
    |> halt()
  end

  def call(conn, {:error, :user_not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "User not found."})
  end

  def call(conn, {:error, :reset_token_expired}) do
    handle_error(conn, "Reset token expired - request a new one")
  end

  def call(conn, {:error, :password_reset_failed}) do
    handle_error(conn, "Failed to reset password.")
  end

  defp handle_error(conn, message) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: message})
  end
end
