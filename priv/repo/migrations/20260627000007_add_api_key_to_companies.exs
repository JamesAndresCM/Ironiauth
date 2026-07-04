defmodule Ironiauth.Repo.Migrations.AddApiKeyToCompanies do
  use Ecto.Migration

  def change do
    alter table(:companies) do
      add :api_key, :string
    end

    execute "UPDATE companies SET api_key = md5(random()::text || id::text || clock_timestamp()::text)"

    execute "ALTER TABLE companies ALTER COLUMN api_key SET NOT NULL"

    create unique_index(:companies, [:api_key])
  end
end
