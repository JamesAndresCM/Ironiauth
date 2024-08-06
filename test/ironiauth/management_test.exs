defmodule Ironiauth.ManagementTest do
  use Ironiauth.DataCase

  alias Ironiauth.Management

  # describe "companies" do
  #   alias Ironiauth.Management.Company

  #   import Ironiauth.ManagementFixtures

  #   @invalid_attrs %{name: nil, domain: nil}

  #   test "list_companies/0 returns all companies" do
  #     company = company_fixture()
  #     assert Management.list_companies() == [company]
  #   end

  #   test "get_company!/1 returns the company with given id" do
  #     company = company_fixture()
  #     assert Management.get_company!(company.id) == company
  #   end

  #   test "create_company/1 with valid data creates a company" do
  #     valid_attrs = %{name: "some name", domain: "some domain"}

  #     assert {:ok, %Company{} = company} = Management.create_company(valid_attrs)
  #     assert company.name == "some name"
  #     assert company.domain == "some domain"
  #   end

  #   test "create_company/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Management.create_company(@invalid_attrs)
  #   end

  #   test "update_company/2 with valid data updates the company" do
  #     company = company_fixture()
  #     update_attrs = %{name: "some updated name", domain: "some updated domain"}

  #     assert {:ok, %Company{} = company} = Management.update_company(company, update_attrs)
  #     assert company.name == "some updated name"
  #     assert company.domain == "some updated domain"
  #   end

  #   test "update_company/2 with invalid data returns error changeset" do
  #     company = company_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Management.update_company(company, @invalid_attrs)
  #     assert company == Management.get_company!(company.id)
  #   end

  #   test "delete_company/1 deletes the company" do
  #     company = company_fixture()
  #     assert {:ok, %Company{}} = Management.delete_company(company)
  #     assert_raise Ecto.NoResultsError, fn -> Management.get_company!(company.id) end
  #   end

  #   test "change_company/1 returns a company changeset" do
  #     company = company_fixture()
  #     assert %Ecto.Changeset{} = Management.change_company(company)
  #   end
  # end
end
