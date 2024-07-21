defmodule IroniauthWeb.SessionsControllerTest do
  use IroniauthWeb.ConnCase
require IEx
  import Ironiauth.AccountsFixtures
  import Ironiauth.ManagementFixtures
  alias Ironiauth.Repo
  alias Ironiauth.Guardian

  alias Ironiauth.Accounts.User
  alias Ironiauth.Management.Company

  @create_attrs %{
    username: "nameless",
    email: "some@do.com",
    password: "password_hash",
    password_confirmation: "password_hash"
  }

  @invalid_attrs %{
    username: "json",
    email: "json@do.com",
    password: "password",
    password_confirmation: "password_hash"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user" do
    test "renders register user link when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/sign_up", user: @create_attrs)
      assert %{"register_url" => register_url} = json_response(conn, 201)
      assert String.contains?(register_url, "select_company")
    end

    test "renders password are not equals", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/sign_up", user: @invalid_attrs)
      assert %{"errors" => errors} = json_response(conn, 422)
      assert List.first(errors["password_confirmation"]) == "does not match confirmation"
    end
  end

  describe "select company" do
    setup [:create_user]
    Enum.map(0..10, fn _ ->
      setup [:create_company]
    end)

    test "signs in a user with valid credentials", %{conn: conn, user: user} do
      user = Repo.get(User, user.id)
      conn = get(conn, ~p"/api/v1/select_company", token: user.uuid, params: %{page: 2})
      assert json_response(conn, 200)["data"]["user"]["id"] == user.id
    end

    test "invalid uuid or nil value", %{conn: conn, user: user} do
      conn = get(conn, ~p"/api/v1/select_company", token: user.uuid, params: %{})
      assert json_response(conn, 200)["error"] == "Invalid token"
    end
  end

  describe "complete user register" do
    setup [:create_user]
    setup [:create_company]
    setup [:create_roles]

    test "associate company with user and return jwt", %{conn: conn, user: user, company: company} do
      user = Repo.get(User, user.id)
      company = Repo.get(Company, company.id)

      conn =
        put(conn, ~p"/api/v1/associate_company",
          user_id: user.id,
          user_uuid: user.uuid,
          company_uuid: company.uuid
        )

      assert Map.has_key?(json_response(conn, 200), "jwt") &&
               json_response(conn, 200)["jwt"] != nil

      user = Repo.get(User, user.id) |> Repo.preload(:roles)
      assert user.active == true
      assert user.company_id == company.id
      assert List.first(user.roles).name == :user
    end
  end

  describe "sign in" do
    setup [:create_user]
    setup [:create_company]
    setup [:create_roles]

    test "login user successfully", %{conn: conn, user: user, company: company} do
      user = Repo.get(User, user.id)
      Ironiauth.Accounts.update_user(user, %{company_id: company.id, active: true})
      conn = post(conn, ~p"/api/v1/sign_in", email: user.email, password: "password_hash")

      assert Map.has_key?(json_response(conn, 200), "jwt") &&
               json_response(conn, 200)["jwt"] != nil
    end

    test "error login password", %{conn: conn, user: user, company: company} do
      user = Repo.get(User, user.id)
      Ironiauth.Accounts.update_user(user, %{company_id: company.id, active: true})
      conn = post(conn, ~p"/api/v1/sign_in", email: user.email, password: "password")
      assert json_response(conn, 401)["error"] == "Login error"
    end
  end

  describe "authenticated endpoint" do
    setup [:create_user]
    setup [:create_company]
    setup [:create_roles]

    setup %{conn: conn, user: user, company: company} do
      authenticated_user(user, company, conn)
    end

    test "current user authenticated", %{conn: conn} do
      conn = get(conn, "/api/v1/users/me")
      assert json_response(conn, 200)["id"] == conn.assigns.current_user.id
      assert json_response(conn, 200)["email"] == conn.assigns.current_user.email
    end
  end

  describe "logout" do
    setup [:create_user]
    setup [:create_company]
    setup [:create_roles]

    setup %{conn: conn, user: user, company: company} do
      authenticated_user(user, company, conn)
    end

    test "logout current user", %{conn: conn} do
      conn = delete(conn, "/api/v1/sign_out")
      assert Map.has_key?(json_response(conn, 200), "msg") == true
      assert String.contains?(json_response(conn, 200)["msg"], "logout successfully")
      assert Map.has_key?(conn.assigns, :current_user) == false
    end
  end

  defp create_user(_) do
    user = user_fixture()
    %{user: user}
  end

  defp create_company(_) do
    company = company_fixture()
    %{company: company}
  end

  defp create_roles(_) do
    create_default_roles()
  end

  defp authenticated_user(user, company, conn) do
    Ironiauth.Accounts.update_user(user, %{company_id: company.id, active: true})
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "bearer: " <> jwt)

    {:ok, conn: conn}
  end
end
