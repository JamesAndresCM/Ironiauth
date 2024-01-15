defmodule IroniauthWeb.UserJSON do
  alias Ironiauth.Accounts.User

  @doc """
  Renders a list of users.
  """
  def index(%{users: users}) do
   %{data: for(user <- users, do: data(user))}
  end

  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{data: data(user)}
  end

  def user(%{user: user}) do
    %{message: "Your current logged as #{user.email}"}
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
