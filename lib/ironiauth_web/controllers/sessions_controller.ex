defmodule IroniauthWeb.SessionsController do
  use IroniauthWeb, :controller
  alias Ironiauth.Accounts
  alias Ironiauth.Accounts.User
  alias Ironiauth.Guardian

  action_fallback IroniauthWeb.FallbackController
  
  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn |> render("jwt.json", jwt: token)
    end
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    case Accounts.token_sign_in(email, password) do
      {:ok, token, _claims} ->
        conn |> render("jwt.json", jwt: token)
      _ ->
        {:error, :unauthorized}
    end
  end
end