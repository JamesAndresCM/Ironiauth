defmodule Ironiauth.Repo.Migrations.CreateMemberships do
  use Ecto.Migration

  def change do
    create table(:memberships) do
      add :uuid, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :company_id, references(:companies, on_delete: :delete_all), null: false
      add :status, :string, default: "active", null: false
      timestamps()
    end

    create unique_index(:memberships, [:user_id, :company_id])
    create index(:memberships, [:user_id])
    create index(:memberships, [:company_id])
  end
end
