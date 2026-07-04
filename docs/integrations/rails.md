# Integración con Ruby on Rails

## Dependencias

```ruby
# Gemfile
gem "jwt", "~> 2.9"
```

## Variables de entorno

```bash
IRONIAUTH_URL=https://tu-ironiauth.com
IRONIAUTH_API_KEY=<api_key de tu company>
```

## Cliente HTTP

```ruby
# app/services/ironiauth_client.rb
require "net/http"
require "json"

class IroniauthClient
  BASE_URL = ENV.fetch("IRONIAUTH_URL")
  API_KEY  = ENV.fetch("IRONIAUTH_API_KEY")

  def self.sign_in(email:, password:)
    post("/api/v1/sign_in", { email:, password: })
  end

  def self.sign_up(username:, email:, password:, password_confirmation:)
    post("/api/v1/sign_up", {
      user: { username:, email:, password:, password_confirmation: }
    })
  end

  def self.fetch_permissions(jwt:)
    get("/api/v1/users/permissions", jwt:)
  end

  # Obtiene la clave pública RSA desde JWKS y la cachea por proceso.
  def self.rsa_public_key
    @rsa_public_key ||= begin
      uri = URI("#{BASE_URL}/.well-known/jwks.json")
      jwks = JSON.parse(Net::HTTP.get(uri))
      JWT::JWK.import(jwks["keys"].first).public_key
    end
  end

  private

  def self.post(path, body)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Post.new(uri, {
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{API_KEY}"
    })
    req.body = body.to_json
    respond(uri, req)
  end

  def self.get(path, jwt:)
    uri = URI("#{BASE_URL}#{path}")
    req = Net::HTTP::Get.new(uri, { "Authorization" => "Bearer #{jwt}" })
    respond(uri, req)
  end

  def self.respond(uri, req)
    res = Net::HTTP.new(uri.host, uri.port).request(req)
    { status: res.code.to_i, body: JSON.parse(res.body) }
  rescue => e
    { status: 503, body: { "error" => e.message } }
  end
end
```

## Concern de autenticación

```ruby
# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  PERMISSIONS_TTL = 5.minutes.to_i

  included do
    helper_method :logged_in?, :can?
  end

  def authenticate!
    redirect_to login_path, alert: "Debes iniciar sesión" unless logged_in?
  end

  def logged_in?
    current_claims.present?
  end

  def can?(permission)
    current_permissions.include?(permission)
  end

  def require_permission!(permission)
    return if can?(permission)
    redirect_to root_path, alert: "Sin permisos para esta acción"
  end

  private

  def current_claims
    @current_claims ||= begin
      token = session[:ironiauth_token]
      return nil unless token

      payload, _ = JWT.decode(token, IroniauthClient.rsa_public_key, true, algorithms: ["RS256"])
      payload
    rescue JWT::ExpiredSignature
      session.delete(:ironiauth_token)
      session.delete(:ironiauth_permissions)
      session.delete(:permissions_cached_at)
      nil
    rescue JWT::DecodeError
      nil
    end
  end

  def current_permissions
    @current_permissions ||= begin
      token = session[:ironiauth_token]
      return [] unless token

      cached_at = session[:permissions_cached_at].to_i
      if cached_at > 0 && Time.now.to_i - cached_at < PERMISSIONS_TTL
        return session[:ironiauth_permissions] || []
      end

      result = IroniauthClient.fetch_permissions(jwt: token)
      permissions = result.dig(:body, "permissions") || []
      session[:ironiauth_permissions] = permissions
      session[:permissions_cached_at] = Time.now.to_i
      permissions
    rescue
      []
    end
  end
end
```

## Incluir en ApplicationController

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authenticatable
end
```

## Proteger acciones en un controller

```ruby
class CarsController < ApplicationController
  before_action :authenticate!, only: %i[new create edit update destroy]
  before_action -> { require_permission!("car#create") }, only: %i[new create]
  before_action -> { require_permission!("car#update") }, only: %i[edit update]
  before_action -> { require_permission!("car#destroy") }, only: %i[destroy]
end
```

## Condicionar vistas

```erb
<% if can?("car#update") %>
  <%= link_to "Editar", edit_car_path(car) %>
<% end %>
```

## Registro e inicio de sesión

```ruby
# SessionsController
def create
  result = IroniauthClient.sign_in(email: params[:email], password: params[:password])
  if result[:body]["jwt"]
    session[:ironiauth_token] = result[:body]["jwt"]
    redirect_to root_path
  else
    flash[:alert] = "Credenciales inválidas"
    render :new
  end
end

def destroy
  session.delete(:ironiauth_token)
  session.delete(:ironiauth_permissions)
  session.delete(:permissions_cached_at)
  redirect_to login_path
end
```
