defmodule IroniauthWeb.CompanyJSON do
  alias Ironiauth.Management.Company

  @doc """
  Renders a list of companies.
  """
  def index(%{companies: companies}) do
    %{data: for(company <- companies, do: data(company))}
  end

  @doc """
  Renders a single company.
  """
  def show(%{company: company}) do
    %{data: data(company)}
  end

  defp data(%Company{} = company) do
    %{
      id: company.id,
      name: company.name,
      domain: company.domain
    }
  end
end
