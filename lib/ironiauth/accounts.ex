defmodule Ironiauth.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ironiauth.Repo

  alias Ironiauth.Accounts.User
  alias Ironiauth.Accounts.UserRole
  alias Ironiauth.Accounts.Membership
  alias Ironiauth.Accounts.Role
  alias Ironiauth.Guardian
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(company_uuid) do
    from u in User,
      join: m in Membership, on: m.user_id == u.id,
      join: c in Ironiauth.Management.Company, on: m.company_id == c.id,
      where: c.uuid == ^company_uuid
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  # Model B: busca el usuario escopado a la company antes de verificar password.
  # El mismo email puede existir en distintas companies como usuarios completamente independientes.
  def token_sign_in(email, password, company_uuid) do
    query =
      from u in User,
        join: m in Membership, on: m.user_id == u.id,
        join: c in Ironiauth.Management.Company, on: m.company_id == c.id,
        where: u.email == ^email and c.uuid == ^company_uuid

    case Repo.one(query) do
      nil ->
        dummy_checkpw()
        {:error, :unauthorized}

      user ->
        if checkpw(password, user.password_hash) do
          Guardian.create_token(user, %{company_uuid: company_uuid, user_uuid: user.uuid})
        else
          {:error, :unauthorized}
        end
    end
  end

  # Crea un usuario y su membership en la company de forma atómica.
  # Verifica que el email no exista ya en esa company (Model B: unicidad por company).
  def create_user_for_company(attrs, company) do
    email = attrs["email"] || attrs[:email]

    if email_taken_in_company?(email, company.id) do
      {:error, :email_taken_in_company}
    else
      Repo.transaction(fn ->
        with {:ok, user} <- create_user(attrs),
             {:ok, _}    <- create_membership(%{user_id: user.id, company_id: company.id}) do
          user
        else
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    end
  end

  defp email_taken_in_company?(email, company_id) do
    from(u in User,
      join: m in Membership, on: m.user_id == u.id,
      where: u.email == ^email and m.company_id == ^company_id
    )
    |> Repo.exists?()
  end

  def create_membership(attrs \\ %{}) do
    %Membership{}
    |> Membership.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_uuid(token, status \\ false) do
    case Ecto.UUID.cast(token) do
      {:ok, uuid} ->
        case Repo.get_by(User, uuid: uuid, active: status) do
          user when not is_nil(user) -> {:ok, user}
          _ -> {:error, "User not found"}
        end

      :error ->
        {:error, "Invalid token"}
    end
  end

  def get_user_by_id_and_uuid(id, uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} ->
        case {:ok, Repo.get_by(User, id: id, uuid: uuid, active: false)} do
          {:ok, nil} ->
            {:error, "user not found"}

          {:ok, result} ->
            {:ok, result}
        end

      :error ->
        {:error, "user not found"}
    end
  end

  def create_user_role(attrs \\ %{}) do
    {:ok, role} = find_role_by_name(attrs[:role_name])

    %UserRole{}
    |> UserRole.changeset(Map.put(attrs, :role_id, role.id))
    |> Repo.insert()
  end

  def find_role_by_name(role_name) do
    case Repo.get_by(Role, name: role_name) do
      nil ->
        {:error, "role not found"}

      role ->
        {:ok, role}
    end
  end

  def admin?(%User{} = user) do
    with {:ok, role} <- find_role_by_name(:admin),
         %UserRole{} <- Repo.get_by(UserRole, user_id: user.id, role_id: role.id) do
      true
    else
      _ -> false
    end
  end

  def superadmin?(%User{} = user) do
    with {:ok, role} <- find_role_by_name(:superadmin),
         %UserRole{} <- Repo.get_by(UserRole, user_id: user.id, role_id: role.id) do
      true
    else
      _ -> false
    end
  end

  def role_names(%User{} = user) do
    user_roles = user |> Repo.preload(:roles)
    user_roles.roles |> Enum.map(& &1.name)
  end

  def get_by_email_active_in_company(email, company_id) when is_binary(email) do
    query =
      from u in User,
        join: m in Membership, on: m.user_id == u.id,
        where: u.email == ^email and u.active == true and m.company_id == ^company_id

    case Repo.one(query) do
      nil -> nil
      user -> {:ok, user}
    end
  end

  def set_token_on_user(user) do
    attrs = %{
      "password_reset_token" => SecureRandom.urlsafe_base64(),
      "password_reset_sent_at" => NaiveDateTime.utc_now()
    }

    user
    |> User.update_changeset(attrs)
    |> Repo.update!()
  end

  def update_reset_password_user(%User{} = user, attrs) do
    user
    |> User.reset_password_changeset(attrs)
    |> Repo.update()
  end

  def valid_token?(token_sent_at) do
    current_time = NaiveDateTime.utc_now()
    NaiveDateTime.diff(current_time, token_sent_at) < 7200
  end

  def get_user_from_token(token) do
    Repo.get_by(User, password_reset_token: token)
  end

  def get_permissions_by_user_uuid(user_uuid, company_id) do
    case Repo.get_by(User, uuid: user_uuid) do
      nil -> {:error, :user_not_found}
      user -> {:ok, load_permissions(user.id, company_id)}
    end
  end

  defp load_permissions(user_id, company_id) do
    from(p in Ironiauth.Management.Permission,
      join: gp in Ironiauth.Management.GroupPermission, on: gp.permission_id == p.id,
      join: g in Ironiauth.Management.Group, on: gp.group_id == g.id,
      join: ug in Ironiauth.Accounts.UserGroup, on: ug.group_id == g.id,
      where: ug.user_id == ^user_id and g.company_id == ^company_id,
      select: p.name,
      distinct: true)
    |> Repo.all()
  end

end
