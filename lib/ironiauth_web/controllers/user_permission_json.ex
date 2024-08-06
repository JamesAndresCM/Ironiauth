defmodule IroniauthWeb.UserPermissionJSON do
  @doc """
  Renders a single user permission.
  """
  def show(%{user_permission: user_permission}) do
    %{data: user_permission}
  end
end