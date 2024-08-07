defmodule IroniauthWeb.CompanyPermissionsController do
  use IroniauthWeb, :controller

  alias Ironiauth.Management
  alias Ironiauth.Management.Permission
  alias IroniauthWeb.Plugs.IsAdmin
  alias Ironiauth.Services.PaginatorService

  action_fallback IroniauthWeb.FallbackController
  plug IsAdmin when action in [:create, :index]
  plug :set_permission when action in [:delete, :update]

  defp set_permission(conn, _params) do
    permission_id = conn.params["id"]

    permission = Management.get_permission(permission_id, conn.assigns.current_user.company_id)

    case permission do
      nil ->
        error_message = %{"errors" => %{"detail" => "Permission not found"}} |> Jason.encode!()

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, error_message)
        |> halt()

      permission ->
        assign(conn, :permission, permission)
    end
  end

  def create(conn, %{"permission" => permission_params}) do
    company = Management.get_company!(conn.assigns.current_user.company_id)

    with {:ok, %Permission{} = permission} <-
           Management.create_company_permissions(company, permission_params) do
      conn
      |> put_status(:created)
      |> render(:show, permission: permission)
    end
  end

  def update(conn, %{"id" => _id, "permission" => permission_params}) do
    with {:ok, %Permission{} = permission} <-
           Management.update_permission(conn.assigns.permission, permission_params) do
      conn
      |> put_status(:ok)
      |> render(:show, permission: permission)
    end
  end

  def index(conn, params) do
    permissions = Management.get_company_permissions(conn.assigns.current_user.company_id)
    paginator = permissions |> PaginatorService.new(permissions)

    meta_data = %{
      page_number: paginator.page_number,
      per_page: paginator.per_page,
      total_pages: paginator.total_pages,
      total_elements: paginator.total_elements
    }
    render(conn, :index, permission: paginator.entries, meta: meta_data)
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, %Permission{}} <- Management.delete_permission(conn.assigns.permission) do
      send_resp(conn, :no_content, "")
    end
  end
end
