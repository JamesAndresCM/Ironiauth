defmodule Ironiauth.AuthErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{error: to_string(type)})

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(401, body)
  end
end