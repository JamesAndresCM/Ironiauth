defmodule IroniauthWeb.ManageLiveAuth do
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign: 2]

  use Phoenix.VerifiedRoutes,
    endpoint: IroniauthWeb.Endpoint,
    router: IroniauthWeb.Router

  def on_mount(:default, _params, session, socket) do
    case validate_admin(session["manage_jwt"], session["manage_company_uuid"]) do
      {:ok, user, company} ->
        {:cont,
         assign(socket,
           manage_user: user,
           manage_company: company,
           manage_redirect_uri: session["manage_redirect_uri"] || ""
         )}

      _ ->
        {:halt, redirect(socket, to: ~p"/manage")}
    end
  end

  defp validate_admin(nil, _), do: {:error, :no_session}
  defp validate_admin(_, nil), do: {:error, :no_session}
  defp validate_admin(_, ""), do: {:error, :no_session}

  defp validate_admin(jwt, company_uuid) when is_binary(company_uuid) and company_uuid != "" do
    with {:ok, claims} <- Ironiauth.Guardian.decode_and_verify(jwt),
         {:ok, user} <- Ironiauth.Guardian.resource_from_claims(claims),
         true <- Ironiauth.Accounts.admin?(user),
         {:ok, company} <- Ironiauth.Management.get_company_by_uuid(company_uuid) do
      {:ok, user, company}
    else
      _ -> {:error, :unauthorized}
    end
  end

  defp validate_admin(_jwt, _), do: {:error, :no_company}
end
