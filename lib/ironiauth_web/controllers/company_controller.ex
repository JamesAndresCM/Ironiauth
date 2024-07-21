defmodule IroniauthWeb.CompanyController do
  use IroniauthWeb, :controller

  alias Ironiauth.Management
  alias Ironiauth.Management.Company
  alias IroniauthWeb.Plugs.IsAdmin
  alias Ironiauth.Services.PaginatorService

  action_fallback IroniauthWeb.FallbackController
  plug IsAdmin when action in [:create, :update, :delete]

  def index(conn, params) do
    companies = Management.list_companies()
    paginator = companies |> PaginatorService.new(params)

    meta_data = %{
      page_number: paginator.page_number,
      per_page: paginator.per_page,
      total_pages: paginator.total_pages,
      total_elements: paginator.total_elements
    }
    render(conn, :index, companies: paginator.entries, meta: meta_data)
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
