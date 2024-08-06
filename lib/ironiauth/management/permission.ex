defmodule Ironiauth.Management.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field :name, :string
    field :description, :string
    belongs_to :company, Ironiauth.Management.Company

    timestamps()
  end

  @doc false
  def changeset(permission, attrs) do
    permission
    |> cast(attrs, [:name, :description, :company_id])
    |> validate_required([:name, :description])
    |> unique_constraint(:name, name: :permissions_name_company_id_index)
  end
end
