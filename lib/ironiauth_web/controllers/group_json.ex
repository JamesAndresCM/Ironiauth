defmodule IroniauthWeb.GroupJSON do
  alias Ironiauth.Management.Group

  def index(%{groups: groups}) do
    %{data: Enum.map(groups, &data/1)}
  end

  def show(%{group: group}) do
    %{data: data(group)}
  end

  defp data(%Group{} = group) do
    %{
      id: group.id,
      uuid: group.uuid,
      name: group.name
    }
  end
end
