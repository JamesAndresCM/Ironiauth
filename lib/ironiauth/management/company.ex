defmodule Ironiauth.Management.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :domain, :string
    field :uuid, Ecto.UUID
    timestamps()
    has_many :permissions, Ironiauth.Management.Permission
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :domain])
    |> validate_required([:name, :domain])
    |> unique_constraint(:domain)
    |> unique_constraint(:name)
  end
end
