defmodule Ironiauth.Services.PaginatorService do
  import Ecto.Query
  alias Ironiauth.Repo
  @page 1
  @per_page 10
  defstruct [:entries, :page_number, :per_page, :total_pages, :total_elements]
  
  def new(query, params) do
    page_number = params |> Map.get("page", @page) |> to_int
    per_page = params |> Map.get("per_page", @per_page) |> to_int
    

    %__MODULE__{
      entries: entries(query, page_number, per_page),
      page_number: page_number,
      per_page: per_page,
      total_elements: total_elements(query),
      total_pages: total_pages(query, per_page)
    }
  end
  
  defp ceiling(float) do
    t = trunc(float)

    case float - t do
      neg when neg < 0 ->
        t
      pos when pos > 0 ->
        t + 1
      _ -> t
    end
  end
  
  defp total_elements(query) do
    query |> Repo.all |> length
  end

  defp entries(query, page_number, per_page) do
    offset = per_page * (page_number - @page)
    
    query
    |> limit([_], ^per_page)
    |> offset([_], ^offset)
    |> Repo.all
  end
  
  defp to_int(i) when is_integer(i), do: i
  defp to_int(s) when is_binary(s) do
    case Integer.parse(s) do
      {i, _} -> i
      :error -> :error
    end
  end
  
  defp total_pages(query, per_page) do
    count = query
    |> exclude(:order_by)
    |> exclude(:preload)
    |> exclude(:select)
    |> select([e], count(e.id))
    |> Repo.one

    if count == nil do
      0
    else
      ceiling(count / per_page)
    end
  end
end