defmodule IroniauthWeb.UserPermissionController do
  use IroniauthWeb, :controller

  action_fallback IroniauthWeb.FallbackController
  alias Ironiauth.Management
  alias Ironiauth.Accounts.UserPermission
  alias IroniauthWeb.Plugs.IsAdmin
  plug IsAdmin when action in [:create, :delete]

  def create(conn, %{"id" => id , "permission" => %{"id" => permission_id} = permission_params}) do
    permission_id = Map.get(permission_params, "id")
    user_id = Map.get(conn.params, "id") |> String.to_integer

    try do
      {:ok, user_permission} = Management.create_user_permission(%{user_id: user_id, permission_id: permission_id})
      data = Management.show_user_permission(user_permission.id)
      render(conn, :show, user_permission: data)
    rescue
      _ ->
        {:error, :user_permission}
    end
  end

  def delete(conn, %{"id" => id}) do
    try do
      user_permission = Management.get_permission!(id)

      with {:ok, %UserPermission{}} <- Management.delete_user_permission(user_permission) do
        send_resp(conn, :no_content, "")
      end
    rescue
      _ ->
        {:error, :not_found}
    end
  end
end