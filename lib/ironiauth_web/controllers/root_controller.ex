defmodule IroniauthWeb.RootController do
  use IroniauthWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      service: "Ironiauth",
      version: "1.0",
      status: "ok",
      jwks_uri: "/.well-known/jwks.json"
    })
  end

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "Not found"})
  end
end
