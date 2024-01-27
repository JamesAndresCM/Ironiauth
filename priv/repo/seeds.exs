# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Ironiauth.Repo.insert!(%Ironiauth.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Ironiauth.Accounts.Role
alias Ironiauth.Management.Company
alias Ironiauth.Repo

Enum.map(Ironiauth.Accounts.Role.role_types, fn {x, _} -> Repo.insert(%Role{name: x}) end)

companies = [
  %{
    name: "coca cola",
    domain: "cocacolacompany.com",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second)
  },
  %{
    name: "nike",
    domain: "nike.com",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second)
  },
  %{
    name: "snk",
    domain: "snk.com",
    inserted_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second),
    updated_at: NaiveDateTime.truncate(NaiveDateTime.utc_now, :second)
  }
]

Repo.insert_all(Company, companies)
