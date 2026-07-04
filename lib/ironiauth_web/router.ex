defmodule IroniauthWeb.Router do
  use IroniauthWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
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


  # Catch-all — debe ir al final, después de todas las rutas definidas
  scope "/", IroniauthWeb do
    pipe_through :api
    match :*, "/*path", RootController, :not_found
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ironiauth, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: IroniauthWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
