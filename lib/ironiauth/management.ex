defmodule Ironiauth.Management do
  @moduledoc """
  The Management context.
  """

  import Ecto.Query, warn: false
  alias Ironiauth.Repo

  alias Ironiauth.Management.{Company, Permission}
  alias Ironiauth.Accounts.{User, UserPermission}

  @doc """
  Returns the list of companies.

  ## Examples

      iex> list_companies()
      [%Company{}, ...]

  """
  def list_companies() do
    from c in Company
  end

  @doc """
  Gets a single company.

  Raises `Ecto.NoResultsError` if the Company does not exist.

  ## Examples

      iex> get_company!(123)
      %Company{}

      iex> get_company!(456)
      ** (Ecto.NoResultsError)

  """
  def get_company!(id), do: Repo.get!(Company, id)

  def get_company_by_uuid(uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} ->
        {:ok , Repo.get_by(Company, uuid: uuid)}
      :error ->
        {:error, "Company not found"}
    end
  end

  @doc """
  Creates a company.

  ## Examples

      iex> create_company(%{field: value})
      {:ok, %Company{}}

      iex> create_company(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_permission(attrs \\ %{}) do
    %UserPermission{}
    |> UserPermission.changeset(attrs)
    |> Repo.insert()
  end

  def delete_user_permission(%UserPermission{} = user_permission) do
    Repo.delete(user_permission)
  end

  def show_user_permission(id) do
    query = from up in UserPermission,
            join: u in User, on: up.user_id == u.id,
            join: p in Permission, on: up.permission_id == p.id,
            join: c in Company, on: p.id == c.id, where: up.id == ^id,
            select: %{
              id: up.id,
              user: %{
                id: u.id,
                email: u.email
              },
              permission: %{
                name: p.name,
                description: p.description,
                company: %{
                  name: c.name,
                  domain: c.domain
                }
              }
            }
    Repo.one(query)
  end

  def get_user_permissions(user_id) do
    query = from up in UserPermission,
            join: p in Permission, on: up.permission_id == p.id,
            join: c in Company, on: c.id == p.company_id,
            where: up.user_id == ^user_id,
            select: %{
              permission: %{
                name: p.name,
                description: p.description,
                company: %{
                  name: c.name,
                  domain: c.domain
                }
              }
            }
    Repo.all(query)
  end

  def get_permission!(id), do: Repo.get!(UserPermission, id)

  def delete_user_permission(%UserPermission{} = user_permission) do
    Repo.delete(user_permission)
  end

  @doc """
  Updates a company.

  ## Examples

      iex> update_company(company, %{field: new_value})
      {:ok, %Company{}}

      iex> update_company(company, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a company.

  ## Examples

      iex> delete_company(company)
      {:ok, %Company{}}

      iex> delete_company(company)
      {:error, %Ecto.Changeset{}}

  """
  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking company changes.

  ## Examples

      iex> change_company(company)
      %Ecto.Changeset{data: %Company{}}

  """
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  def create_company_permissions(%Company{} = company, attrs \\ %{}) do
    attrs = Map.put(attrs, "company_id", company.id)

    %Permission{} |> Permission.changeset(attrs) |> Repo.insert()
  end

  def get_company_permissions(company_id) do
    from p in Permission, where: p.company_id == ^company_id
  end

  def get_permission(id, company_id), do: Repo.get_by(Permission, [id: id, company_id: company_id])

  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  def update_permission(%Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
  end
end
