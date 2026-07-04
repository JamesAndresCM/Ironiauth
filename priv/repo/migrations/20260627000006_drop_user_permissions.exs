defmodule Ironiauth.Repo.Migrations.DropUserPermissions do
  use Ecto.Migration

  def change do
    drop table(:user_permissions)
  end
end
