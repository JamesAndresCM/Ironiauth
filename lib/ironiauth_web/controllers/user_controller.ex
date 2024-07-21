defmodule IroniauthWeb.UserController do
  use IroniauthWeb, :controller

  alias Ironiauth.Accounts
  alias Ironiauth.Accounts.User
  alias IroniauthWeb.Plugs.IsAdmin

  action_fallback IroniauthWeb.FallbackController
  alias Ironiauth.Services.PaginatorService
  plug IsAdmin when action in [:index, :show]
  plug :is_authorized_user when action in [:update, :delete]

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
    user = Accounts.get_user!(id)
    render(conn, :show, user: user)
  end

  def me(conn, _params) do
    conn |> render("user.json", user: conn.assigns.current_user)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    with {:ok, %User{} = user} <- Accounts.update_user(conn.assigns.current_user, user_params) do
      render(conn, :show, user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
