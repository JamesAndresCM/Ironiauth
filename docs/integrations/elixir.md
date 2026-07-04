# Integración con Elixir / Phoenix

## Dependencias

```elixir
# mix.exs
{:req, "~> 0.5"},         # HTTP client moderno
{:jose, "~> 1.11"},       # JWT con RS256 (ya incluido si usas Guardian)
{:jason, "~> 1.4"},       # JSON (ya incluido en Phoenix)
```

## Variables de entorno

```bash
IRONIAUTH_URL=https://tu-ironiauth.com
IRONIAUTH_API_KEY=<api_key de tu company>
```

## Cliente HTTP

```elixir
# lib/mi_app/ironiauth_client.ex
defmodule MiApp.IroniauthClient do
  @base_url System.get_env("IRONIAUTH_URL") || raise "IRONIAUTH_URL no definida"
  @api_key  System.get_env("IRONIAUTH_API_KEY") || raise "IRONIAUTH_API_KEY no definida"

  def sign_in(email, password) do
    Req.post("#{@base_url}/api/v1/sign_in",
      json: %{email: email, password: password},
      headers: [{"Authorization", "Bearer #{@api_key}"}]
    )
    |> handle_response()
  end

  def sign_up(attrs) do
    Req.post("#{@base_url}/api/v1/sign_up",
      json: %{user: attrs},
      headers: [{"Authorization", "Bearer #{@api_key}"}]
    )
    |> handle_response()
  end

  def fetch_permissions(jwt) do
    Req.get("#{@base_url}/api/v1/users/permissions",
      headers: [{"Authorization", "Bearer #{jwt}"}]
    )
    |> handle_response()
  end

  # Clave pública RSA cacheada con persistent_term para no consultar JWKS en cada request.
  def rsa_public_key do
    case :persistent_term.get({__MODULE__, :public_key}, nil) do
      nil -> fetch_and_cache_public_key()
      key -> key
    end
  end

  defp fetch_and_cache_public_key do
    {:ok, %{body: body}} = Req.get("#{@base_url}/.well-known/jwks.json")
    jwk = body["keys"] |> List.first() |> JOSE.JWK.from_map()
    :persistent_term.put({__MODULE__, :public_key}, jwk)
    jwk
  end

  defp handle_response({:ok, %{body: body}}), do: {:ok, body}
  defp handle_response({:error, reason}), do: {:error, reason}
end
```

## Validación del JWT

```elixir
# lib/mi_app/auth.ex
defmodule MiApp.Auth do
  alias MiApp.IroniauthClient

  @ttl_seconds 300  # 5 minutos de caché de permisos

  def decode_jwt(token) do
    jwk = IroniauthClient.rsa_public_key()

    case JOSE.JWT.verify_strict(jwk, ["RS256"], token) do
      {true, %JOSE.JWT{fields: claims}, _jws} -> {:ok, claims}
      {false, _, _} -> {:error, :invalid_signature}
    end
  rescue
    _ -> {:error, :invalid_token}
  end

  def get_permissions(jwt, cache_key) do
    # Usar Process dictionary como caché simple. En producción usar ETS o Redis.
    case Process.get({:ironiauth_permissions, cache_key}) do
      {permissions, cached_at} when :os.system_time(:second) - cached_at < @ttl_seconds ->
        permissions

      _ ->
        case IroniauthClient.fetch_permissions(jwt) do
          {:ok, %{"permissions" => permissions}} ->
            Process.put({:ironiauth_permissions, cache_key}, {permissions, :os.system_time(:second)})
            permissions

          _ ->
            []
        end
    end
  end
end
```

## Plug de autenticación

```elixir
# lib/mi_app_web/plugs/authenticate.ex
defmodule MiAppWeb.Plugs.Authenticate do
  import Plug.Conn
  alias MiApp.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Auth.decode_jwt(token) do
      conn
      |> assign(:current_token, token)
      |> assign(:current_claims, claims)
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "No autenticado"}))
        |> halt()
    end
  end
end
```

## Controller con permisos

```elixir
# lib/mi_app_web/controllers/car_controller.ex
defmodule MiAppWeb.CarController do
  use MiAppWeb, :controller
  alias MiApp.Auth

  plug MiAppWeb.Plugs.Authenticate

  def create(conn, params) do
    with :ok <- require_permission(conn, "car#create") do
      # lógica de negocio...
      json(conn, %{msg: "auto creado"})
    end
  end

  def update(conn, %{"id" => id} = params) do
    with :ok <- require_permission(conn, "car#update") do
      json(conn, %{msg: "auto #{id} actualizado"})
    end
  end

  def delete(conn, %{"id" => id}) do
    with :ok <- require_permission(conn, "car#destroy") do
      send_resp(conn, :no_content, "")
    end
  end

  defp require_permission(conn, permission) do
    token = conn.assigns.current_token
    cache_key = conn.assigns.current_claims["user_uuid"]
    permissions = Auth.get_permissions(token, cache_key)

    if permission in permissions do
      :ok
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(403, Jason.encode!(%{error: "Permiso requerido: #{permission}"}))
      |> halt()
      |> then(fn _ -> {:error, :forbidden} end)
    end
  end
end
```

## Router

```elixir
# lib/mi_app_web/router.ex
pipeline :ironiauth do
  plug MiAppWeb.Plugs.Authenticate
end

scope "/api", MiAppWeb do
  pipe_through [:api, :ironiauth]

  resources "/cars", CarController, except: [:new, :edit]
end
```
