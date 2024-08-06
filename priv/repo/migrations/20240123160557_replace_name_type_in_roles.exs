defmodule Ironiauth.Repo.Migrations.ReplaceNameTypeInRoles do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE roles ALTER COLUMN name TYPE integer USING name::integer")
    alter table(:roles) do
      modify :name, :integer, default: 0
    end
  end
end
