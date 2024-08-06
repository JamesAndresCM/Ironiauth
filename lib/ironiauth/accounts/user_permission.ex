defmodule Ironiauth.Accounts.UserPermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_permissions" do
    belongs_to :user, Ironiauth.Accounts.User
    belongs_to :permission, Ironiauth.Management.Permission

    timestamps()
  end

  @required_fields ~w(user_id permission_id)a
  @doc false
  def changeset(user_permission, attrs) do
    user_permission
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
