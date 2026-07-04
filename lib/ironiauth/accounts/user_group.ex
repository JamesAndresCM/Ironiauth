defmodule Ironiauth.Accounts.UserGroup do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_groups" do
    belongs_to :user, Ironiauth.Accounts.User
    belongs_to :group, Ironiauth.Management.Group
    timestamps()
  end

  def changeset(user_group, attrs) do
    user_group
    |> cast(attrs, [:user_id, :group_id])
    |> validate_required([:user_id, :group_id])
    |> unique_constraint([:user_id, :group_id])
  end
end
