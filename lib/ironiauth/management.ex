defmodule Ironiauth.Management do
  @moduledoc """
  The Management context.
  """

  import Ecto.Query, warn: false
  alias Ironiauth.Repo

  alias Ironiauth.Management.{Company, Permission, Group, GroupPermission}
  alias Ironiauth.Accounts.UserGroup

  def list_companies() do
    from c in Company
  end

  def get_company!(id), do: Repo.get!(Company, id)

  def get_company_by_uuid(uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} ->
        case Repo.get_by(Company, uuid: uuid) do
          nil -> {:error, "Company not found"}
          company -> {:ok, company}
        end
      :error ->
        {:error, "Company not found"}
    end
  end

  def get_company_by_api_key(api_key) do
    case Repo.get_by(Company, api_key: api_key) do
      nil -> {:error, "Invalid API key"}
      company -> {:ok, company}
    end
  end

  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> Repo.insert()
  end

  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> Repo.update()
  end

  def delete_company(%Company{} = company) do
    Repo.delete(company)
  end

  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  # Permissions

  def create_company_permissions(%Company{} = company, attrs \\ %{}) do
    attrs = Map.put(attrs, "company_id", company.id)
    %Permission{} |> Permission.changeset(attrs) |> Repo.insert()
  end

  def get_company_permissions(company_id) do
    from p in Permission, where: p.company_id == ^company_id
  end

  def get_permission(id, company_id), do: Repo.get_by(Permission, id: id, company_id: company_id)

  def get_permission!(id), do: Repo.get!(Permission, id)

  def delete_permission(%Permission{} = permission) do
    Repo.delete(permission)
  end

  def update_permission(%Permission{} = permission, attrs) do
    permission
    |> Permission.changeset(attrs)
    |> Repo.update()
  end

  # Groups

  def list_groups(company_id) do
    from(g in Group, where: g.company_id == ^company_id)
    |> Repo.all()
  end

  def get_group!(id), do: Repo.get!(Group, id)

  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  # Group permissions

  def add_permission_to_group(attrs) do
    %GroupPermission{}
    |> GroupPermission.changeset(attrs)
    |> Repo.insert()
  end

  def remove_permission_from_group(group_id, permission_id) do
    case Repo.get_by(GroupPermission, group_id: group_id, permission_id: permission_id) do
      nil -> {:error, :not_found}
      gp -> Repo.delete(gp)
    end
  end

  # User groups

  def add_user_to_group(attrs) do
    %UserGroup{}
    |> UserGroup.changeset(attrs)
    |> Repo.insert()
  end

  def remove_user_from_group(group_id, user_id) do
    case Repo.get_by(UserGroup, group_id: group_id, user_id: user_id) do
      nil -> {:error, :not_found}
      ug -> Repo.delete(ug)
    end
  end

  def get_user_permissions(user_id, company_id) do
    from(p in Permission,
      join: gp in GroupPermission, on: gp.permission_id == p.id,
      join: g in Group, on: gp.group_id == g.id,
      join: ug in UserGroup, on: ug.group_id == g.id,
      where: ug.user_id == ^user_id and g.company_id == ^company_id,
      select: p.name,
      distinct: true)
    |> Repo.all()
  end
end
