defmodule IroniauthWeb.SessionsController do
  use IroniauthWeb, :controller
  alias Ironiauth.Accounts
  alias Ironiauth.Management
  alias Ironiauth.Accounts.User
  alias Ironiauth.Guardian

  action_fallback IroniauthWeb.FallbackController

  def create(conn, %{"user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(user_params),
         user <- Accounts.get_user!(user.id) do
      conn
      |> put_status(:created)
      |> render("register_url.json", user_uuid: user.uuid)
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

  def select_company(conn, %{"token" => token}) do
    case Accounts.get_user_by_uuid(token) do
      {:error, msg} ->
        conn |> json(%{error: msg})

      {:ok, user} ->
        companies = Management.list_companies()
        conn |> render("companies.json", companies: companies, user: user)
    end
  end

  def associate_company(conn, %{
        "company_uuid" => company_uuid,
        "user_id" => user_id,
        "user_uuid" => user_uuid
      }) do
    with {:ok, user} <- Accounts.get_user_by_id_and_uuid(user_id, user_uuid),
         {:ok, company} <- Management.get_company_by_uuid(company_uuid),
         {:ok, _updated_user} <-
           Accounts.update_user(user, %{company_id: company.id, active: true}),
         {:ok, _user_role} <- Accounts.create_user_role(%{user_id: user.id, role_name: :user}),
         {:ok, token, _claims} <-
           Guardian.create_token(user, %{company_uuid: company.uuid, user_uuid: user.uuid}) do
      conn |> render("jwt.json", jwt: token)
    else
      {:error, msg} ->
        conn |> json(%{error: msg})
    end
  end
end
