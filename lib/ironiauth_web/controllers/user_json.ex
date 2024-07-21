defmodule IroniauthWeb.UserJSON do
  alias Ironiauth.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users, meta: meta}) do
   %{data: for(user <- users, do: data(user)), meta: meta}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  def user(%{user: user}) do
    %{id: user.id, email: user.email, roles: Ironiauth.Accounts.role_names(user)}
  end

  def detail_user(%{user: user}) do
    %{id: user.id, email: user.email }
  end

  defp data(%User{} = user) do
    %{
      uuid: user.uuid,
      username: user.username,
      email: user.email
    }
  end
end
