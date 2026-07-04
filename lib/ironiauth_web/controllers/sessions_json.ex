defmodule IroniauthWeb.SessionsJSON do
  def jwt(%{jwt: jwt}) do
    %{jwt: jwt}
  end

  def register_url(%{user_uuid: user_uuid}) do
    %{user_uuid: user_uuid}
  end

  def show(%{user: user}) do
    %{uuid: user.uuid}
  end
end