defmodule Ironiauth.Repo.Migrations.AddPassResetTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :password_reset_token, :string
      add :password_reset_sent_at, :naive_datetime
    end
  end
end
