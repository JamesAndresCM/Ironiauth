defmodule IroniauthWeb.AuthController do
  use IroniauthWeb, :controller

  alias Ironiauth.{Accounts, Management, Guardian}
  alias Ironiauth.Services.User.ForgotPasswordService

  # GET /login?company_uuid=<uuid>&redirect_uri=<url>
  def login(conn, %{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri}) do
    case Management.get_company_by_uuid(company_uuid) do
      {:ok, company} ->
        render(conn, :login,
          company: company,
          redirect_uri: redirect_uri,
          email: "",
          error: nil
        )

      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "Company not found"})
    end
  end

  def login(conn, _), do: conn |> put_status(:bad_request) |> json(%{error: "Missing company_uuid or redirect_uri"})

  # POST /login
  def do_login(conn, %{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri, "email" => email, "password" => password}) do
    case Accounts.token_sign_in(email, password, company_uuid) do
      {:ok, token, _claims} ->
        redirect(conn, external: append_jwt(redirect_uri, token))

      _ ->
        {:ok, company} = Management.get_company_by_uuid(company_uuid)
        render(conn, :login,
          company: company,
          redirect_uri: redirect_uri,
          email: email,
          error: "Invalid email or password"
        )
    end
  end

  # GET /register?company_uuid=<uuid>&redirect_uri=<url>
  def register(conn, %{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri}) do
    case Management.get_company_by_uuid(company_uuid) do
      {:ok, company} ->
        render(conn, :register,
          company: company,
          redirect_uri: redirect_uri,
          username: "",
          email: "",
          error: nil
        )

      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "Company not found"})
    end
  end

  def register(conn, _), do: conn |> put_status(:bad_request) |> json(%{error: "Missing company_uuid or redirect_uri"})

  # POST /register
  def do_register(conn, %{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri, "user" => user_params}) do
    with {:ok, company} <- Management.get_company_by_uuid(company_uuid),
         {:ok, user}    <- Accounts.create_user_for_company(user_params, company),
         {:ok, _}       <- Accounts.create_user_role(%{user_id: user.id, role_name: :user}),
         {:ok, token, _} <- Guardian.create_token(user, %{company_uuid: company.uuid, user_uuid: user.uuid}) do
      redirect(conn, external: append_jwt(redirect_uri, token))
    else
      {:error, :email_taken_in_company} ->
        {:ok, company} = Management.get_company_by_uuid(company_uuid)
        render(conn, :register,
          company: company,
          redirect_uri: redirect_uri,
          username: user_params["username"] || "",
          email: user_params["email"] || "",
          error: "Email has already been taken"
        )

      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, company} = Management.get_company_by_uuid(company_uuid)
        render(conn, :register,
          company: company,
          redirect_uri: redirect_uri,
          username: user_params["username"] || "",
          email: user_params["email"] || "",
          error: changeset_error_message(changeset)
        )

      _ ->
        {:ok, company} = Management.get_company_by_uuid(company_uuid)
        render(conn, :register,
          company: company,
          redirect_uri: redirect_uri,
          username: user_params["username"] || "",
          email: user_params["email"] || "",
          error: "Registration failed. Please try again."
        )
    end
  end

  # GET /forgot-password?company_uuid=<uuid>&redirect_uri=<url>
  def forgot_password(conn, %{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri}) do
    case Management.get_company_by_uuid(company_uuid) do
      {:ok, company} ->
        render(conn, :forgot_password, company: company, redirect_uri: redirect_uri, sent: false)

      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "Company not found"})
    end
  end

  def forgot_password(conn, _), do: conn |> put_status(:bad_request) |> json(%{error: "Missing company_uuid"})

  # POST /forgot-password
  def do_forgot_password(conn, %{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri, "email" => email}) do
    case Management.get_company_by_uuid(company_uuid) do
      {:ok, company} ->
        ForgotPasswordService.call(email, company, redirect_uri)
        render(conn, :forgot_password, company: company, redirect_uri: redirect_uri, sent: true)

      {:error, _} ->
        conn |> put_status(:not_found) |> json(%{error: "Company not found"})
    end
  end

  # GET /reset-password?token=<token>&company_uuid=<uuid>&redirect_uri=<url>
  def reset_password_form(conn, %{"token" => token} = params) do
    company_uuid = Map.get(params, "company_uuid", "")
    redirect_uri = Map.get(params, "redirect_uri", "")
    render(conn, :reset_password, token: token, company_uuid: company_uuid, redirect_uri: redirect_uri, error: nil)
  end

  def reset_password_form(conn, _) do
    conn |> put_status(:bad_request) |> json(%{error: "Missing token"})
  end

  # POST /reset-password
  def do_reset_password(conn, %{"token" => token, "company_uuid" => company_uuid, "redirect_uri" => redirect_uri, "user" => pass_attrs}) do
    service = Ironiauth.Services.User.ResetPasswordService.new(token, pass_attrs)

    case Ironiauth.Services.User.ResetPasswordService.call(service) do
      {:ok, _user} ->
        login_url = build_login_url(company_uuid, redirect_uri)
        render(conn, :reset_password_success, login_url: login_url)

      {:error, :reset_token_expired} ->
        render(conn, :reset_password, token: token, company_uuid: company_uuid, redirect_uri: redirect_uri, error: "This reset link has expired. Please request a new one.")

      {:error, :user_not_found} ->
        render(conn, :reset_password, token: token, company_uuid: company_uuid, redirect_uri: redirect_uri, error: "Invalid reset link.")

      {:error, :password_reset_failed} ->
        render(conn, :reset_password, token: token, company_uuid: company_uuid, redirect_uri: redirect_uri, error: "Could not reset password. Please check your input and try again.")
    end
  end

  def do_reset_password(conn, %{"token" => token, "user" => pass_attrs}) do
    do_reset_password(conn, %{"token" => token, "company_uuid" => "", "redirect_uri" => "", "user" => pass_attrs})
  end

  defp build_login_url("", _redirect_uri), do: "/login"
  defp build_login_url(company_uuid, redirect_uri) do
    "/login?" <> URI.encode_query(%{"company_uuid" => company_uuid, "redirect_uri" => redirect_uri})
  end


  defp append_jwt(redirect_uri, token) do
    uri = URI.parse(redirect_uri)
    existing = URI.decode_query(uri.query || "")
    query = URI.encode_query(Map.put(existing, "jwt", token))
    URI.to_string(%{uri | query: query})
  end

  defp changeset_error_message(changeset) do
    Enum.map_join(changeset.errors, ". ", fn {field, {msg, opts}} ->
      interpolated = Enum.reduce(opts, msg, fn {key, val}, acc ->
        String.replace(acc, "%{#{key}}", to_string(val))
      end)
      "#{Phoenix.Naming.humanize(field)}: #{interpolated}"
    end)
  end
end
