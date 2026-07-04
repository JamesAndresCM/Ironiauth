defmodule IroniauthWeb.Plugs.ApiKeyAuth do
  import Plug.Conn
  alias Ironiauth.Management

  def init(default), do: default

  def call(conn, _opts) do
    with ["Bearer " <> api_key] <- get_req_header(conn, "authorization"),
         {:ok, company} <- Management.get_company_by_api_key(api_key) do
      conn |> assign(:current_company, company)
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Invalid or missing API key"}))
        |> halt()
    end
  end
end
