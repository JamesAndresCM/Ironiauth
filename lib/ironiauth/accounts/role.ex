defmodule Ironiauth.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  @roles [user: 0, admin: 1, superadmin: 2]

  schema "roles" do
    field :name, Ecto.Enum, values: @roles, default: :user
    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name])
  end

  def role_types do
    Ecto.Enum.mappings(Ironiauth.Accounts.Role, :name) |> Map.new
  end

  def is_admin?(name) when name == :admin, do: true
  def is_admin?(_), do: false
  def is_user?(name) when name == :user, do: true
  def is_user?(_), do: false
  def is_superadmin?(name) when name == :superadmin, do: true
  def is_superadmin?(_), do: false
end
