defmodule Ironiauth.Repo.Migrations.RemoveCompanyIdFromUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :company_id, references(:companies)
    end
  end
end
