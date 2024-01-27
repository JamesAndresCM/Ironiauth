defmodule Ironiauth.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ironiauth.Accounts` context.
  """

  alias Ironiauth.Accounts.Role
  alias Ironiauth.Repo
  @doc """
  Generate a unique user email.
  """
  @counter :rand.uniform()
  def unique_user_email, do: "some_email#{@counter}" <> "@example.com"

  @doc """
  Generate a unique user username.
  """
  def unique_user_username, do: "some username#{System.unique_integer([:positive])}"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        password: "password_hash",
        password_confirmation: "password_hash",
        username: unique_user_username(),
      })
      |> Ironiauth.Accounts.create_user()

    user
  end

  def role_fixture(attrs \\ %{}) do
    {:ok, role} = Repo.insert(%Role{name: attrs[:name]})
    role
  end

  def create_default_roles() do
    Enum.map(Ironiauth.Accounts.Role.role_types, fn {x, _} -> Repo.insert(%Role{name: x}) end)
  end
end
