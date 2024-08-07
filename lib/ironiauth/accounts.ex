defmodule Ironiauth.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Ironiauth.Repo

  alias Ironiauth.Accounts.User
  alias Ironiauth.Accounts.UserRole
  alias Ironiauth.Accounts.Role
  alias Ironiauth.Guardian
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users(company_id) do
    from u in User, where: u.company_id == ^company_id
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

  def token_sign_in(email, password) do
    case email_password_auth(email, password) do
      {:ok, user} ->
        user = user |> Repo.preload(:company)
        Guardian.create_token(user, %{company_uuid: user.company.uuid, user_uuid: user.uuid})

      _ ->
        {:error, :unauthorized}
    end
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
         nil <- Repo.get_by(UserRole, user_id: user.id, role_id: role.id) do
      false
    else
      _ -> true
    end
  end

  def role_names(%User{} = user) do
    user_roles = user |> Repo.preload(:roles)
    user_roles.roles |> Enum.map(& &1.name)
  end

  def get_by_email_active(email) when is_binary(email) do
    case Repo.get_by(User, email: email, active: true) do
      nil ->
        nil

      user ->
        {:ok, user}
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
    Time.diff(current_time, token_sent_at) < 7200
  end

  def get_user_from_token(token) do
    Repo.get_by(User, password_reset_token: token)
  end

  def get_user_by_id_and_company_id!(user_id, company_id) do
    Repo.get_by!(User, id: user_id, company_id: company_id)
  end

  defp email_password_auth(email, password) when is_binary(email) and is_binary(password) do
    with {:ok, user} <- get_by_email(email), do: verify_password(password, user)
  end

  defp get_by_email(email) when is_binary(email) do
    case Repo.get_by(User, email: email) do
      nil ->
        dummy_checkpw()
        {:error, "Login error."}

      user ->
        {:ok, user}
    end
  end

  defp verify_password(password, %User{} = user) when is_binary(password) do
    if checkpw(password, user.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_password}
    end
  end
end
