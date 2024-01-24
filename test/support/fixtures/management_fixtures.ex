defmodule Ironiauth.ManagementFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ironiauth.Management` context.
  """

  @doc """
  Generate a unique company domain.
  """
  def unique_company_domain, do: "some domain#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique company name.
  """
  def unique_company_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a company.
  """
  def company_fixture(attrs \\ %{}) do
    {:ok, company} =
      attrs
      |> Enum.into(%{
        domain: unique_company_domain(),
        name: unique_company_name()
      })
      |> Ironiauth.Management.create_company()

    company
  end
end
