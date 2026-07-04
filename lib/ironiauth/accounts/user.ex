defmodule Ironiauth.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :active, :boolean, default: false
    field :uuid, Ecto.UUID
    field :password_reset_token, :string
    field :password_reset_sent_at, :naive_datetime
    has_many :memberships, Ironiauth.Accounts.Membership
    has_many :companies, through: [:memberships, :company]
    has_many :user_roles, Ironiauth.Accounts.UserRole
    has_many :roles, through: [:user_roles, :role]
    has_many :user_groups, Ironiauth.Accounts.UserGroup
    has_many :groups, through: [:user_groups, :group]
    timestamps()
  end

  @required_fields_create ~w(username email password password_confirmation)a
  @cast_fields ~w(username email password password_confirmation active)a
  @update_fields ~w(active username password_reset_token password_reset_sent_at)a
  @reset_password_fields ~w(password password_confirmation password_reset_token password_reset_sent_at)a

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields_create)
    |> validate_format(:email, ~r/@/) 
    |> validate_length(:password, min: 8) 
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_confirmation(:password, on: [:create])
    |> put_password_hash
  end

  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, @update_fields, [])
  end

  def reset_password_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, @reset_password_fields)
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password)
    |> put_password_hash
  end


  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}}
        ->
          put_change(changeset, :password_hash, hashpwsalt(pass))
      _ ->
          changeset
    end
  end
end
