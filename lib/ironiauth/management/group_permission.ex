defmodule Ironiauth.Management.GroupPermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "group_permissions" do
    belongs_to :group, Ironiauth.Management.Group
    belongs_to :permission, Ironiauth.Management.Permission
    timestamps()
  end

  def changeset(group_permission, attrs) do
    group_permission
    |> cast(attrs, [:group_id, :permission_id])
    |> validate_required([:group_id, :permission_id])
    |> unique_constraint([:group_id, :permission_id])
  end
end
