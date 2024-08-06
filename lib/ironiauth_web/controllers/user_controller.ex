defmodule IroniauthWeb.UserController do
  use IroniauthWeb, :controller

  alias Ironiauth.Accounts
  alias Ironiauth.Accounts.User
  alias IroniauthWeb.Plugs.IsAdmin
  alias Ironiauth.Management

  action_fallback IroniauthWeb.FallbackController
  alias Ironiauth.Services.PaginatorService
  plug IsAdmin when action in [:index, :show, :delete]
  plug :is_authorized_user when action in [:update]
  plug :set_user when action in [:delete, :show]

  defp set_user(conn, _params) do
    user_id = conn.params["id"]

    try do
      assign(conn, :user, Accounts.get_user!(user_id))
    rescue
      _ ->
        conn
        |> json(%{error: "User not found"})
        |> halt()     
    end
  end

  defp is_authorized_user(conn, _params) do
    user_id = conn.params["id"]
    with {:ok, user} <- Accounts.get_user_by_uuid(user_id, true),
        session_user <- conn.assigns.current_user do
        if user.uuid == session_user.uuid do
          conn
        else
          conn
          |> json(%{error: "Operation not permitted"})
          |> halt()
        end
    else
      {:error, msg} ->
        conn
        |> json(%{error: "resource not permitted"})
        |> halt()
    end
  end

  def index(conn, params) do
    users = Accounts.list_users(conn.assigns.current_user.company_id)
    paginator = users |> PaginatorService.new(users)

    meta_data = %{
      page_number: paginator.page_number,
      per_page: paginator.per_page,
      total_pages: paginator.total_pages,
      total_elements: paginator.total_elements
    }
    render(conn, :index, users: paginator.entries, meta: meta_data)
  end

  def show(conn, %{"id" => id}) do
    render(conn, :show, user: conn.assigns.user)
  end

  def me(conn, _params) do
    conn |> render("user.json", user: conn.assigns.current_user)
  end

  def permissions(conn, _params) do
    data = Management.get_user_permissions(conn.assigns.current_user.id)
    render(conn, :user_permissions, permissions: data)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.update_user(conn.assigns.current_user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, %User{}} <- Accounts.delete_user(conn.assigns.user) do
      send_resp(conn, :no_content, "")
    end
  end
end
