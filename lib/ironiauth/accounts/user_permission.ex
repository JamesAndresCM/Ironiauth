defmodule Ironiauth.Accounts.UserPermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_permissions" do

    field :user_id, :id
    field :permission_id, :id

    timestamps()
  end

  @doc false
  def changeset(user_permission, attrs) do
    user_permission
    |> cast(attrs, [])
    |> validate_required([])
  end
end
