defmodule IroniauthWeb.GroupController do
  use IroniauthWeb, :controller

  alias Ironiauth.Management
  alias IroniauthWeb.Plugs.IsAdmin

  action_fallback IroniauthWeb.FallbackController
  plug IsAdmin

  def index(conn, _params) do
    company = conn.assigns.current_company
    groups = Management.list_groups(company.id)
    render(conn, :index, groups: groups)
  end

  def create(conn, %{"group" => %{"name" => name}}) do
    company = conn.assigns.current_company
    with {:ok, group} <- Management.create_group(%{name: name, company_id: company.id}) do
      conn |> put_status(:created) |> render(:show, group: group)
    end
  end

  def delete(conn, %{"id" => id}) do
    group = Management.get_group!(id)
    with {:ok, _} <- Management.delete_group(group) do
      send_resp(conn, :no_content, "")
    end
  end

  def add_permission(conn, %{"group_id" => group_id, "permission_id" => permission_id}) do
    with {:ok, _} <- Management.add_permission_to_group(%{
           group_id: String.to_integer(group_id),
           permission_id: String.to_integer(permission_id)
         }) do
      send_resp(conn, :no_content, "")
    end
  end

  def remove_permission(conn, %{"group_id" => group_id, "permission_id" => permission_id}) do
    with {:ok, _} <- Management.remove_permission_from_group(
           String.to_integer(group_id),
           String.to_integer(permission_id)
         ) do
      send_resp(conn, :no_content, "")
    end
  end

  def add_user(conn, %{"group_id" => group_id, "user_id" => user_id}) do
    with {:ok, _} <- Management.add_user_to_group(%{
           group_id: String.to_integer(group_id),
           user_id: String.to_integer(user_id)
         }) do
      send_resp(conn, :no_content, "")
    end
  end

  def remove_user(conn, %{"group_id" => group_id, "user_id" => user_id}) do
    with {:ok, _} <- Management.remove_user_from_group(
           String.to_integer(group_id),
           String.to_integer(user_id)
         ) do
      send_resp(conn, :no_content, "")
    end
  end
end
