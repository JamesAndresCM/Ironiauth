defmodule IroniauthWeb.Plugs.IsSuperAdmin do
  import Plug.Conn
  alias Ironiauth.Accounts

  def init(default), do: default

  def call(conn, _opts) do
    user = Accounts.get_user!(conn.assigns.current_user.id)

    if Accounts.superadmin?(user) do
      conn
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(403, Jason.encode!(%{error: "Superadmin access required"}))
      |> halt()
    end
  end
end
