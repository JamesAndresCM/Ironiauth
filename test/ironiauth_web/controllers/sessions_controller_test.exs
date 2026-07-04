defmodule IroniauthWeb.SessionsControllerTest do
  use IroniauthWeb.ConnCase

  import Ironiauth.AccountsFixtures
  import Ironiauth.ManagementFixtures

  alias Ironiauth.Accounts
  alias Ironiauth.Guardian

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
    setup [:create_company, :create_roles]

    test "returns jwt when data is valid", %{conn: conn, company: company} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> company.api_key)
        |> post(~p"/api/v1/sign_up", user: @create_attrs)

      assert %{"jwt" => jwt} = json_response(conn, 201)
      assert jwt != nil
    end

    test "renders error when passwords don't match", %{conn: conn, company: company} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> company.api_key)
        |> post(~p"/api/v1/sign_up", user: @invalid_attrs)

      assert %{"errors" => errors} = json_response(conn, 422)
      assert List.first(errors["password_confirmation"]) == "does not match confirmation"
    end

    test "rejects duplicate email within same company", %{conn: conn, company: company} do
      conn
      |> put_req_header("authorization", "Bearer " <> company.api_key)
      |> post(~p"/api/v1/sign_up", user: @create_attrs)

      conn2 =
        build_conn()
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer " <> company.api_key)
        |> post(~p"/api/v1/sign_up", user: @create_attrs)

      assert %{"errors" => %{"email" => _}} = json_response(conn2, 422)
    end
  end

  describe "sign in" do
    setup [:create_company, :create_roles]

    test "login user successfully", %{conn: conn, company: company} do
      {:ok, _user} = Accounts.create_user_for_company(@create_attrs, company)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> company.api_key)
        |> post(~p"/api/v1/sign_in", email: @create_attrs.email, password: @create_attrs.password)

      assert %{"jwt" => jwt} = json_response(conn, 200)
      assert jwt != nil
    end

    test "error with wrong password", %{conn: conn, company: company} do
      {:ok, _user} = Accounts.create_user_for_company(@create_attrs, company)

      conn =
        conn
        |> put_req_header("authorization", "Bearer " <> company.api_key)
        |> post(~p"/api/v1/sign_in", email: @create_attrs.email, password: "wrong_password")

      assert json_response(conn, 401)["error"] == "Login error"
    end
  end

  describe "authenticated endpoint" do
    setup [:create_company, :create_roles]

    setup %{conn: conn, company: company} do
      attrs = %{
        username: unique_user_username(),
        email: unique_user_email(),
        password: "password_hash",
        password_confirmation: "password_hash"
      }

      {:ok, user} = Accounts.create_user_for_company(attrs, company)
      {:ok, conn: authenticated_conn(conn, user, company), user: user}
    end

    test "current user authenticated", %{conn: conn, user: user} do
      conn = get(conn, "/api/v1/users/me")
      assert json_response(conn, 200)["id"] == user.id
      assert json_response(conn, 200)["email"] == user.email
    end
  end

  describe "logout" do
    setup [:create_company, :create_roles]

    setup %{conn: conn, company: company} do
      attrs = %{
        username: unique_user_username(),
        email: unique_user_email(),
        password: "password_hash",
        password_confirmation: "password_hash"
      }

      {:ok, user} = Accounts.create_user_for_company(attrs, company)
      {:ok, conn: authenticated_conn(conn, user, company)}
    end

    test "logout current user", %{conn: conn} do
      conn = delete(conn, "/api/v1/sign_out")
      assert Map.has_key?(json_response(conn, 200), "msg") == true
      assert String.contains?(json_response(conn, 200)["msg"], "logout successfully")
      assert Map.has_key?(conn.assigns, :current_user) == false
    end
  end

  defp authenticated_conn(conn, user, company) do
    {:ok, jwt, _} =
      Guardian.create_token(user, %{company_uuid: company.uuid, user_uuid: user.uuid})

    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", "Bearer " <> jwt)
  end

  defp create_company(_) do
    %{company: company_fixture()}
  end

  defp create_roles(_) do
    create_default_roles()
  end
end
