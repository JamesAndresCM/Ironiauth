defmodule Ironiauth.Repo.Migrations.RemoveGlobalEmailUniqueFromUsers do
  use Ecto.Migration

  def change do
    # Model B: email es único por company, no globalmente.
    # El mismo email puede representar usuarios distintos en companies distintas.
    drop unique_index(:users, [:email])

    # Mantener índice no-único para performance en búsquedas por email.
    create index(:users, [:email])
  end
end
