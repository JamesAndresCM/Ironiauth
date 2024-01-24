defmodule IroniauthWeb.SessionsJSON do
  def jwt(%{jwt: jwt}) do
    %{jwt: jwt}
  end

  def register_url(%{user_uuid: user_uuid}) do
    register_url = build_register_url(user_uuid)
    %{
      register_url: register_url
    }
  end

  def show(%{user: user}) do
    %{
      uuid: user.uuid
    }
  end

   defp build_register_url(user_uuid) do
    base_url = System.get_env("BASE_URL") || "http://localhost:4000"
    register_path = "/api/v1/select_company?token=#{user_uuid}"
    "#{base_url}#{register_path}"
   end

   def companies(%{companies: companies, user: user}) do
    %{data: %{companies: for(company <- companies, do: data(company)), user: %{id: user.id, uuid: user.uuid}}}
   end

   defp data(company) do
    %{ 
      uuid: company.uuid,
      name: company.name 
    }
   end
end