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
    belongs_to :company, Ironiauth.Management.Company
    has_many :user_roles, Ironiauth.Accounts.UserRole
    has_many :roles, through: [:user_roles, :role]
    timestamps()
  end

  @required_fields_create ~w(username email password password_confirmation)a
  @cast_fields ~w(username email password password_confirmation company_id active)a
  @update_fields ~w(active company_id)a

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, @cast_fields)
    |> validate_required(@required_fields_create)
    |> validate_format(:email, ~r/@/) 
    |> validate_length(:password, min: 8) 
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> put_password_hash
  end

  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, @update_fields, [])
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
