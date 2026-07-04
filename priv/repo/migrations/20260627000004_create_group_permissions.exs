defmodule Ironiauth.Repo.Migrations.CreateGroupPermissions do
  use Ecto.Migration

  def change do
    create table(:group_permissions) do
      add :group_id, references(:groups, on_delete: :delete_all), null: false
      add :permission_id, references(:permissions, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:group_permissions, [:group_id, :permission_id])
    create index(:group_permissions, [:group_id])
    create index(:group_permissions, [:permission_id])
  end
end
