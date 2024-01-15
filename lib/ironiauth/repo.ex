defmodule Ironiauth.Repo do
  use Ecto.Repo,
    otp_app: :ironiauth,
    adapter: Ecto.Adapters.Postgres


  @doc """
  Returns total of rows.

  ## Examples

      iex> Repo.count("users")
      6
  """
  def count(table) do
    aggregate(table, :count, :id)
  end

  @doc """
  Returns the first row.

  ## Examples

      iex> first(User) |> Repo.one
      [%User{}, ...]

  """
  def first(table) do
    table |> first()
  end

  @doc """
  Returns the last row.

  ## Examples

      iex> last(User) |> Repo.one
      [%User{}, ...]

  """
  def last(table) do
    table |> last()
  end
end
