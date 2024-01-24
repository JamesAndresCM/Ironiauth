defmodule IroniauthWeb.CompanyController do
  use IroniauthWeb, :controller

  alias Ironiauth.Management
  alias Ironiauth.Management.Company

  action_fallback IroniauthWeb.FallbackController

  def index(conn, _params) do
    companies = Management.list_companies()
    render(conn, :index, companies: companies)
  end

  def create(conn, %{"company" => company_params}) do
    with {:ok, %Company{} = company} <- Management.create_company(company_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/companies/#{company}")
      |> render(:show, company: company)
    end
  end

  def show(conn, %{"id" => id}) do
    company = Management.get_company!(id)
    render(conn, :show, company: company)
  end

  def update(conn, %{"id" => id, "company" => company_params}) do
    company = Management.get_company!(id)

    with {:ok, %Company{} = company} <- Management.update_company(company, company_params) do
      render(conn, :show, company: company)
    end
  end

  def delete(conn, %{"id" => id}) do
    company = Management.get_company!(id)

    with {:ok, %Company{}} <- Management.delete_company(company) do
      send_resp(conn, :no_content, "")
    end
  end
end
