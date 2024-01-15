defmodule IroniauthWeb.SessionsJSON do
  def jwt(%{jwt: jwt}) do
    %{jwt: jwt}
  end
end