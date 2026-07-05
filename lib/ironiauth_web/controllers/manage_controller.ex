defmodule IroniauthWeb.ManageController do
  use IroniauthWeb, :controller

  alias Ironiauth.Accounts

  # GET /manage  — punto de entrada desde la app cliente
  # Guarda company_uuid y redirect_uri en sesión, luego redirige al dashboard o al login.
  def enter(conn, params) do
    company_uuid = params["company_uuid"] || get_session(conn, :manage_company_uuid) || ""
    redirect_uri = params["redirect_uri"] || get_session(conn, :manage_redirect_uri) || ""

    conn =
      conn
      |> put_session(:manage_company_uuid, company_uuid)
      |> put_session(:manage_redirect_uri, redirect_uri)

    case validate_admin_session(get_session(conn, :manage_jwt), company_uuid) do
      :ok ->
        redirect(conn, to: ~p"/manage/dashboard")

      :not_admin ->
        if redirect_uri != "" do
          redirect(conn, external: redirect_uri)
        else
          conn
          |> put_status(:forbidden)
          |> put_resp_content_type("text/html")
          |> send_resp(403, "<html lang=\"en\"><head><meta charset=\"utf-8\"/><title>Access Denied - Ironiauth</title><style>*{box-sizing:border-box;margin:0;padding:0}body{font-family:-apple-system,sans-serif;background:#f1f5f9;display:flex;align-items:center;justify-content:center;min-height:100vh}.card{background:white;border-radius:12px;padding:2.5rem;max-width:380px;width:100%;box-shadow:0 4px 24px rgba(0,0,0,.1);text-align:center}h1{font-size:1.25rem;font-weight:700;color:#dc2626;margin-bottom:.5rem}p{color:#64748b;font-size:.9rem;margin-bottom:1.5rem}a{display:inline-block;padding:.5rem 1.25rem;background:#4f46e5;color:white;border-radius:6px;font-size:.85rem;text-decoration:none}a:hover{background:#4338ca}</style></head><body><div class=\"card\"><h1>Access denied</h1><p>Your account does not have admin permissions for this panel.</p><a href=\"javascript:history.back()\">Go back</a></div></body></html>")
        end

      :unauthenticated ->
        # Sin sesión válida — redirige al Hosted UI con redirect_uri apuntando de vuelta a /manage
        # Usamos el host del request para que funcione tanto desde localhost como desde IP local (pruebas móviles)
        base_url = "#{conn.scheme}://#{conn.host}#{if conn.port not in [80, 443], do: ":#{conn.port}"}"
        manage_url = base_url <> "/manage?" <> URI.encode_query(%{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri})
        login_url = "/login?" <> URI.encode_query(%{"company_uuid" => company_uuid, "redirect_uri" => manage_url})
        redirect(conn, to: login_url)
    end
  end

  # GET /manage/logout  (redirect from open_car logout — single sign-out)
  # POST /manage/logout (sign out button inside the admin panel)
  def logout(conn, params) do
    redirect_uri =
      params["redirect_uri"] || get_session(conn, :manage_redirect_uri) || ""

    conn =
      conn
      |> delete_session(:manage_jwt)
      |> delete_session(:manage_company_uuid)
      |> delete_session(:manage_redirect_uri)

    if redirect_uri != "" do
      redirect(conn, external: redirect_uri)
    else
      redirect(conn, to: ~p"/manage")
    end
  end

  defp validate_admin_session(nil, _), do: :unauthenticated
  defp validate_admin_session("", _), do: :unauthenticated
  defp validate_admin_session(_jwt, ""), do: :unauthenticated

  defp validate_admin_session(jwt, company_uuid) do
    with {:ok, claims} <- Ironiauth.Guardian.decode_and_verify(jwt),
         {:ok, user} <- Ironiauth.Guardian.resource_from_claims(claims),
         {:ok, _company} <- Ironiauth.Management.get_company_by_uuid(company_uuid) do
      if Accounts.admin?(user), do: :ok, else: :not_admin
    else
      _ -> :unauthenticated
    end
  end
end
