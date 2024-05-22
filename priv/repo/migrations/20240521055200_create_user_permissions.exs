defmodule Ironiauth.Repo.Migrations.CreateUserPermissions do
  use Ecto.Migration

  def change do
    create table(:user_permissions) do
      add :user_id, references(:users, on_delete: :nothing)
      add :permission_id, references(:permissions, on_delete: :nothing)

      timestamps()
    end

    create index(:user_permissions, [:user_id])
    create index(:user_permissions, [:permission_id])
    create index(:user_permissions, [:user_id, :permission_id], unique: true)
  end
end
