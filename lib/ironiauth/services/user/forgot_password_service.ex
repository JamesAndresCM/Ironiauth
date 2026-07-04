defmodule Ironiauth.Services.User.ForgotPasswordService do
  alias Ironiauth.Accounts

  def call(email, company, redirect_uri \\ "") do
    case Accounts.get_by_email_active_in_company(email, company.id) do
      nil ->
        {:ok, :send_passwd_mailer}

      {:ok, user} ->
        updated_user = Accounts.set_token_on_user(user)

        Task.Supervisor.start_child(Ironiauth.AsyncEmailSupervisor, fn ->
          updated_user
          |> Ironiauth.Mailers.ResetPasswordMailer.password_reset(company.uuid, redirect_uri)
          |> Ironiauth.Mailer.deliver()
        end)

        {:ok, :send_passwd_mailer}
    end
  end
end
