defmodule Ironiauth.Services.User.ResetPasswordService do
  alias Ironiauth.Accounts

  defstruct token: nil, passwd_attrs: nil

  def new(token, passwd_attrs) do
    %__MODULE__{
      token: token,
      passwd_attrs: passwd_attrs
    }
  end

  def call(%__MODULE__{} = context) do
    case Accounts.get_user_from_token(context.token) do
      nil ->
        {:error, :user_not_found}

      user ->
        pass_attrs =
          Map.merge(context.passwd_attrs, %{"password_reset_token" => nil, "password_reset_sent_at" => nil})

        if Accounts.valid_token?(user.password_reset_sent_at) do
          updated_user  = Accounts.update_reset_password_user(user, pass_attrs)
            case updated_user do
              {:ok, _} ->
                {:ok, user}
              _ ->
                {:error, :password_reset_failed}
            end
        else
          {:error, :reset_token_expired}
        end
    end
  end
end
