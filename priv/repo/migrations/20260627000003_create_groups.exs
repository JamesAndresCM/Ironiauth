defmodule Ironiauth.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :uuid, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :name, :string, null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:groups, [:name, :company_id])
    create index(:groups, [:company_id])
  end
end
