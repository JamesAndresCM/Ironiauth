defmodule IroniauthWeb.Plugs.CurrentUser do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        error_message = %{"error" => "User not authenticated"} |> Jason.encode!()
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, error_message)
        |> halt()
      current_user ->
        conn
        |> assign(:current_user, current_user)
    end
  end
end