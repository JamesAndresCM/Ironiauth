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
  def list_users do
    Repo.all(User)
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
        Guardian.encode_and_sign(user)
      _ ->
        {:error, :unauthorized}
    end
  end

  def get_user_by_uuid(token) do
    case Ecto.UUID.cast(token) do
      {:ok, uuid} ->
        case Repo.get_by(User, uuid: uuid, active: false) do
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
    |> Repo.insert
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
    user_roles.roles |> Enum.map(&(&1.name))
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
