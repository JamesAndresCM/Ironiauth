defmodule IroniauthWeb.Plugs.CurrentUser do
  import Plug.Conn
  alias Ironiauth.Management

  def init(default), do: default

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "User not authenticated"}))
        |> halt()

      current_user ->
        claims = Guardian.Plug.current_claims(conn)
        company_uuid = claims["company_uuid"]

        case Management.get_company_by_uuid(company_uuid) do
          {:ok, company} ->
            conn
            |> assign(:current_user, current_user)
            |> assign(:current_company, company)

          _ ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: "Invalid company"}))
            |> halt()
        end
    end
  end
end
