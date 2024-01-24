defmodule Ironiauth.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_roles" do
    belongs_to :role, Ironiauth.Accounts.Role
    belongs_to :user, Ironiauth.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([])
  end
end
