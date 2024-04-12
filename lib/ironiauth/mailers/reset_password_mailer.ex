defmodule Ironiauth.Mailers.ResetPasswordMailer do
  import Swoosh.Email

  def password_reset(user) do
    new()
    |> to({user.username, user.email})
    |> from({"No reply", "no-reply@domain.com"})
    |> subject("Wellcome, #{user.username}!")
    |> html_body("
    <h1>Hello #{user.username}</h1>
    </br>
    <p>Hello #{user.username} your reset password link <a href='localhost:5000/frontend_url/reset_password?token=#{user.password_reset_token}'/>is here</p>")
  end
end