defmodule Ironiauth.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add :name, :string
      add :description, :text
      add :company_id, references(:companies, on_delete: :nothing)

      timestamps()
    end

    create index(:permissions, [:company_id])
    create index(:permissions, [:name, :company_id], unique: true)
  end
end
