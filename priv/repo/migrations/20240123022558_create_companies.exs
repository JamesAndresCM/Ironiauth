defmodule Ironiauth.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string
      add :domain, :string
      add :uuid, :uuid, null: false, default: fragment("gen_random_uuid()")
      timestamps()
    end

    create unique_index(:companies, [:domain])
    create unique_index(:companies, [:name])
  end
end
