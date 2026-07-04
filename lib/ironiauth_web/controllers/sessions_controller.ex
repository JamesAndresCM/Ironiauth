defmodule IroniauthWeb.SessionsController do
  use IroniauthWeb, :controller
  alias Ironiauth.Accounts
  alias Ironiauth.Guardian
  action_fallback IroniauthWeb.FallbackController

  def create(conn, %{"user" => user_params}) do
    company = conn.assigns.current_company
    with {:ok, user}     <- Accounts.create_user_for_company(user_params, company),
         {:ok, _}        <- Accounts.create_user_role(%{user_id: user.id, role_name: :user}),
         {:ok, token, _} <- Guardian.create_token(user, %{
                              company_uuid: company.uuid,
                              user_uuid: user.uuid
                            }) do
      conn |> put_status(:created) |> render("jwt.json", jwt: token)
    end
  end

  def sign_in(conn, %{"email" => email, "password" => password}) do
    company = conn.assigns.current_company
    case Accounts.token_sign_in(email, password, company.uuid) do
      {:ok, token, _claims} ->
        conn |> render("jwt.json", jwt: token)

      _ ->
        {:error, :unauthorized}
    end
  end

  def sign_out(conn, %{}) do
    token = Guardian.Plug.current_token(conn)
    Guardian.revoke(token)
    conn = %{conn | assigns: Map.delete(conn.assigns, :current_user)}

    conn
    |> put_status(:ok)
    |> json(%{msg: "logout successfully"})
    |> halt()
  end

  def refresh_session(conn, %{}) do
    old_token = Guardian.Plug.current_token(conn)
    case Guardian.decode_and_verify(old_token) do
      {:ok, claims} ->
        case Guardian.resource_from_claims(claims) do
          {:ok, user} ->
            {:ok, _old, {new_token, _new_claims}} = Guardian.refresh_token(old_token, user)
            conn
            |> put_status(:ok)
            |> render("jwt.json", jwt: new_token)
          {:error, _reason} ->
            conn
            |> json(%{error: "error to refresh token"})
            |> halt()
        end
      {:error, _reason} ->
        conn
        |> json(%{error: "error to refresh token"})
        |> halt()
    end
  end

end
