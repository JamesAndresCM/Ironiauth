# Ironiauth

To start your Phoenix server:

  * Run `mix.deps && mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * Rename `.env.example` to `.env` and run `source .env`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# Endpoints
* [Endpoints](https://documenter.getpostman.com/view/3505861/2sA35MyJiB)
* JWT expire in 10 minutes for normal user and admin 90 minutes configure this in `lib/guardian.ex` file or configure values in `.env`

### RestClient/Ruby Example

- Set payload
````
payload = {
 "user": {
   "email": "jhondoe3@gmail.com",
   "username": "jhon doe3",
   "password": "jhon123456",
   "password_confirmation": "jhon123456"
  }
}
````
- Get Response
````
response = RestClient::Request.execute(
   method: :post,
   url: "localhost:4000/api/v1/sign_up",
   headers: {content_type: :json, accept: :json},
   payload: payload.to_json
 )

JSON.parse(response)
````
- Get details
````
response = RestClient.get("http://localhost:4000/api/v1/select_company?token=666e815b-dea9-4b7d-a6b6-2eb2a74f8d08")
JSON.parse(response)
payload = {
    "company_uuid": "fe8b208f-8bd6-4dc0-9932-b82f6ea694e5",
    "user_id": 25,
    "user_uuid": "666e815b-dea9-4b7d-a6b6-2eb2a74f8d08"
}

response = RestClient::Request.execute(
   method: :put,
   url: "localhost:4000/api/v1/associate_company",
   headers: {content_type: :json, accept: :json},
   payload: payload.to_json
 )
````
- Get & Decode JWT, [secret here](https://github.com/JamesAndresCM/Ironiauth/blob/main/config/config.exs#L47)
````
token = JSON.parse(response)["jwt"]
JWT.decode(token, secret, true, algorithm: 'HS512')
````

# Testing
* Run `mix test`
