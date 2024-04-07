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

# Testing
* Run `mix test`
