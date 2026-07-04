defmodule Ironiauth.Services.User.ForgotPasswordService do
  alias Ironiauth.Accounts

  def call(email) do
    case Accounts.get_by_email_active(email) do
      nil ->
        {:ok, :send_passwd_mailer}

      {:ok, user} ->
        updated_user = Accounts.set_token_on_user(user)

        Task.Supervisor.start_child(Ironiauth.AsyncEmailSupervisor, fn ->
          updated_user
          |> Ironiauth.Mailers.ResetPasswordMailer.password_reset()
          |> Ironiauth.Mailer.deliver()
        end)

        {:ok, :send_passwd_mailer}
    end
  end
end
