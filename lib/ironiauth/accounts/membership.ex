defmodule Ironiauth.Accounts.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  schema "memberships" do
    field :uuid, Ecto.UUID, autogenerate: true
    field :status, :string, default: "active"
    belongs_to :user, Ironiauth.Accounts.User
    belongs_to :company, Ironiauth.Management.Company
    timestamps()
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :company_id, :status])
    |> validate_required([:user_id, :company_id])
    |> unique_constraint([:user_id, :company_id])
  end
end
