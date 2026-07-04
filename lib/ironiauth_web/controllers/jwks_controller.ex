defmodule IroniauthWeb.JwksController do
  use IroniauthWeb, :controller

  def index(conn, _params) do
    public_key_map =
      Application.get_env(:ironiauth, :jwks_public_key, %{})
      |> Map.merge(%{"use" => "sig", "alg" => "RS256", "kid" => "ironiauth-1"})

    json(conn, %{keys: [public_key_map]})
  end
end
