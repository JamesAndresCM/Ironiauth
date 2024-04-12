defmodule IroniauthWeb.Plugs.IsAdmin do
  import Plug.Conn
  alias Ironiauth.Accounts

  def init(default), do: default

  def call(conn, _opts) do
    user_id = conn.assigns.current_user.id
    if Accounts.admin?(Accounts.get_user!(user_id)) do
      conn
    else
      error_message = %{"error" => "Resource not permitted"} |> Jason.encode!()
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(401, error_message)
      |> halt()
    end
  end
end
