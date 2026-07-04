defmodule Ironiauth.Mailers.ResetPasswordMailer do
  import Swoosh.Email

  def password_reset(user, company_uuid \\ "", redirect_uri \\ "") do
    base_url = Application.get_env(:ironiauth, :base_url, IroniauthWeb.Endpoint.url())
    params = URI.encode_query(%{
      "token"        => user.password_reset_token,
      "company_uuid" => company_uuid,
      "redirect_uri" => redirect_uri
    })
    reset_link = "#{base_url}/reset-password?#{params}"

    new()
    |> to({user.username, user.email})
    |> from({"Ironiauth", "no-reply@ironiauth.com"})
    |> subject("Reset your password")
    |> html_body("""
    <h2>Reset your password</h2>
    <p>Hi #{user.username},</p>
    <p>Click the link below to reset your password. This link expires in 2 hours.</p>
    <p><a href="#{reset_link}">Reset password</a></p>
    <p>If you didn't request this, you can ignore this email.</p>
    """)
    |> text_body("""
    Reset your password

    Hi #{user.username},

    Click the link below to reset your password (expires in 2 hours):
    #{reset_link}

    If you didn't request this, ignore this email.
    """)
  end
end
