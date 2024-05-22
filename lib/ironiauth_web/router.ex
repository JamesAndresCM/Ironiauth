defmodule IroniauthWeb.Router do
  use IroniauthWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", IroniauthWeb do
    pipe_through :api
  end

  pipeline :jwt_authenticated do
    plug IroniauthWeb.Plugs.Guardian.AuthPipeline
    plug IroniauthWeb.Plugs.CurrentUser
  end

  scope "/api/v1", IroniauthWeb do
    pipe_through :api
    post "/sign_up", SessionsController, :create
    post "/sign_in", SessionsController, :sign_in
    get "/select_company", SessionsController, :select_company
    put "/associate_company", SessionsController, :associate_company
    post "/forgot_password", PasswordsController, :forgot_password
    put "/reset_password/:token", PasswordsController, :reset_password
  end

  scope "/api/v1", IroniauthWeb do
    pipe_through [:api, :jwt_authenticated]

    get "/users/me", UserController, :me
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
