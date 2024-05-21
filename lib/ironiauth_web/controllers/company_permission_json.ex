defmodule IroniauthWeb.CompanyPermissionsJSON do
  alias Ironiauth.Management.Permission

  def index(%{permission: permissions}) do
    %{data: for(permission <- permissions, do: data(permission))}
  end
  
  def show(%{permission: permission}) do
    %{data: data(permission)}
  end

  defp data(%Permission{} = permission) do
    %{
      id: permission.id,
      name: permission.name,
      description: permission.description
    }
  end
end