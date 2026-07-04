defmodule Ironiauth.Management.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :domain, :string
    field :uuid, Ecto.UUID
    field :api_key, :string
    timestamps()
    has_many :permissions, Ironiauth.Management.Permission
    has_many :groups, Ironiauth.Management.Group
    has_many :memberships, Ironiauth.Accounts.Membership
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :domain])
    |> validate_required([:name, :domain])
    |> unique_constraint(:domain)
    |> unique_constraint(:name)
    |> put_uuid()
    |> put_api_key()
  end

  defp put_uuid(%Ecto.Changeset{data: %{uuid: nil}} = changeset) do
    put_change(changeset, :uuid, Ecto.UUID.generate())
  end
  defp put_uuid(changeset), do: changeset

  defp put_api_key(%Ecto.Changeset{data: %{api_key: nil}} = changeset) do
    put_change(changeset, :api_key, :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false))
  end
  defp put_api_key(changeset), do: changeset
end
