defmodule Ironiauth.Repo.Migrations.AddActiveAndCompanyIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :active, :boolean, default: false
      add :company_id, references(:companies)
    end
  end
end
