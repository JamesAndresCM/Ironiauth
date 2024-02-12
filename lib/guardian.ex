defmodule Ironiauth.Guardian do
  use Guardian, otp_app: :ironiauth
  @admin_time 90
  @user_time 10

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end
  
  def subject_for_token(_, _) do
    {:error, :reason_for_error}
  end
  
  def resource_from_claims(%{"sub" => id}) do
    resource = Ironiauth.Accounts.get_user!(id)
    {:ok, resource}
  end
  
  def resource_from_claims(_claims) do
    {:error, :reason_for_error}
  end

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_refresh({old_token, old_claims}, {new_token, new_claims}, _options) do
    with {:ok, _, _} <- Guardian.DB.on_refresh({old_token, old_claims}, {new_token, new_claims}) do
      {:ok, {old_token, old_claims}, {new_token, new_claims}}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end

  def create_token(user, user_params \\ %{}) do
    encode_and_sign(user, user_params, expiration_time_for_token(user))
  end

  def refresh_token(old_token, user) do
    refresh(old_token, expiration_time_for_token(user))
  end

  defp expiration_time_for_token(user) do
    if Ironiauth.Accounts.admin?(user) do
      [token_options: "admin", ttl: {@admin_time, :day}]
    else
      [token_options: "access", ttl: {@user_time, :minute}]
    end
  end
end