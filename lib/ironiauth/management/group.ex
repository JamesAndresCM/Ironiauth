defmodule Ironiauth.Management.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :uuid, Ecto.UUID, autogenerate: true
    field :name, :string
    belongs_to :company, Ironiauth.Management.Company
    has_many :group_permissions, Ironiauth.Management.GroupPermission
    has_many :permissions, through: [:group_permissions, :permission]
    has_many :user_groups, Ironiauth.Accounts.UserGroup
    has_many :users, through: [:user_groups, :user]
    timestamps()
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :company_id])
    |> validate_required([:name, :company_id])
    |> unique_constraint([:name, :company_id])
  end
end
