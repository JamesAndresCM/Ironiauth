defmodule IroniauthWeb.Router do
  use IroniauthWeb, :router
  import Phoenix.LiveView.Router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, html: {IroniauthWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :manage_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :put_root_layout, html: {IroniauthWeb.Layouts, :manage_root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # Company Admin Panel — panel de administración para admins de cada company
  # La app cliente redirige a /manage?company_uuid=<uuid>&redirect_uri=<callback>
  scope "/manage", IroniauthWeb do
    pipe_through :manage_browser
    get  "/",        ManageController, :enter
    get  "/logout",  ManageController, :logout
    post "/logout",  ManageController, :logout
  end

  scope "/manage", IroniauthWeb do
    pipe_through :manage_browser

    live_session :manage,
      on_mount: [{IroniauthWeb.ManageLiveAuth, :default}],
      layout: {IroniauthWeb.Layouts, :manage_app} do
      live "/dashboard",        ManageLive.Dashboard, :dashboard
      live "/groups",           ManageLive.Groups, :groups
      live "/groups/:id",       ManageLive.GroupDetail, :group_detail
      live "/permissions",      ManageLive.Permissions, :permissions
      live "/users",            ManageLive.Users, :users
    end
  end

  # Hosted UI — login/register/forgot-password served por Ironiauth
  # La app cliente redirige a estas URLs con company_uuid y redirect_uri
  scope "/", IroniauthWeb do
    pipe_through :browser
    get "/login", AuthController, :login
    post "/login", AuthController, :do_login
    get "/register", AuthController, :register
    post "/register", AuthController, :do_register
    get "/forgot-password", AuthController, :forgot_password
    post "/forgot-password", AuthController, :do_forgot_password
    get "/reset-password", AuthController, :reset_password_form
    post "/reset-password", AuthController, :do_reset_password
  end

  scope "/", IroniauthWeb do
    pipe_through :api
    get "/", RootController, :index
  end

  pipeline :jwt_authenticated do
    plug IroniauthWeb.Plugs.Guardian.AuthPipeline
    plug IroniauthWeb.Plugs.CurrentUser
  end

  pipeline :api_key_authenticated do
    plug IroniauthWeb.Plugs.ApiKeyAuth
  end

  # JWKS — clave pública para que las apps cliente validen JWTs RS256
  scope "/.well-known", IroniauthWeb do
    pipe_through :api
    get "/jwks.json", JwksController, :index
  end

  # Sin autenticación — reset_password usa el token del email para identificar al user
  scope "/api/v1", IroniauthWeb do
    pipe_through :api
    put "/reset_password/:token", PasswordsController, :reset_password
  end

  # Endpoints que requieren api_key (llamados desde el backend de cada app)
  # forgot_password necesita api_key para saber a qué company pertenece el email
  scope "/api/v1", IroniauthWeb do
    pipe_through [:api, :api_key_authenticated]
    post "/sign_up", SessionsController, :create
    post "/sign_in", SessionsController, :sign_in
    post "/forgot_password", PasswordsController, :forgot_password
  end

  scope "/api/v1", IroniauthWeb do
    pipe_through [:api, :jwt_authenticated]

    get "/users/me", UserController, :me
    get "/users/permissions", UserController, :permissions
    get "/users", UserController, :index
    get "/users/:id", UserController, :show
    put "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete
    delete "/sign_out", SessionsController, :sign_out
    get "/refresh_token", SessionsController, :refresh_session
    resources "/companies", CompanyController, except: [:new, :edit]
    post "/company_permissions", CompanyPermissionsController, :create
    get "/company_permissions", CompanyPermissionsController, :index
    delete "/company_permissions/:id", CompanyPermissionsController, :delete
    put "/company_permissions/:id", CompanyPermissionsController, :update
    get "/groups", GroupController, :index
    post "/groups", GroupController, :create
    delete "/groups/:id", GroupController, :delete
    post "/groups/:group_id/permissions/:permission_id", GroupController, :add_permission
    delete "/groups/:group_id/permissions/:permission_id", GroupController, :remove_permission
    post "/groups/:group_id/users/:user_id", GroupController, :add_user
    delete "/groups/:group_id/users/:user_id", GroupController, :remove_user
  end


  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ironiauth, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: IroniauthWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Catch-all — debe ir al final de todo
  scope "/", IroniauthWeb do
    pipe_through :api
    match :*, "/*path", RootController, :not_found
  end
end
