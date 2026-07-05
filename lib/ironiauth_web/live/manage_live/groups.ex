defmodule IroniauthWeb.ManageLive.Groups do
  use IroniauthWeb, :live_view

  alias Ironiauth.Management

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.manage_company
    page = Management.list_groups_paginated(company.id, 1)
    {:ok, assign(socket, page: page, live_action: :groups, new_group_name: "")}
  end

  @impl true
  def handle_event("create_group", %{"name" => name}, socket) do
    company = socket.assigns.manage_company

    case Management.create_group(%{"name" => String.trim(name), "company_id" => company.id}) do
      {:ok, _group} ->
        page = Management.list_groups_paginated(company.id, 1)
        {:noreply, assign(socket, page: page, new_group_name: "")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not create group. Name may already exist.")}
    end
  end

  def handle_event("delete_group", %{"id" => id}, socket) do
    group = Management.get_group!(String.to_integer(id))

    case Management.delete_group(group) do
      {:ok, _} ->
        company = socket.assigns.manage_company
        page = Management.list_groups_paginated(company.id, socket.assigns.page.page_number)
        {:noreply, assign(socket, page: page)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete group.")}
    end
  end

  def handle_event("go_to_page", %{"n" => n}, socket) do
    company = socket.assigns.manage_company
    page = Management.list_groups_paginated(company.id, String.to_integer(n))
    {:noreply, assign(socket, page: page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="m-page-title">Groups</h1>

    <div class="m-card">
      <div class="m-card-title">Create group</div>
      <form phx-submit="create_group" class="m-form">
        <div>
          <label class="m-label">Group name</label>
          <input class="m-input" type="text" name="name" value={@new_group_name} placeholder="e.g. editors" required />
        </div>
        <button type="submit" class="m-btn">Create</button>
      </form>
    </div>

    <div class="m-card">
      <div class="m-card-title">All groups (<%= @page.total_entries %>)</div>
      <%= if @page.entries == [] do %>
        <div class="m-empty">No groups yet. Create one above.</div>
      <% else %>
        <table class="m-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Permissions</th>
              <th>Users</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <%= for group <- @page.entries do %>
              <tr>
                <td>
                  <.link navigate={~p"/manage/groups/#{group.id}"} style="color:#4f46e5;font-weight:500">
                    <%= group.name %>
                  </.link>
                </td>
                <td><%= length(group.permissions) %></td>
                <td><%= length(group.users) %></td>
                <td style="text-align:right">
                  <button
                    phx-click="delete_group"
                    phx-value-id={group.id}
                    data-confirm={"Delete group '#{group.name}'?"}
                    class="m-btn m-btn-sm m-btn-danger"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <.pagination page={@page} />
      <% end %>
    </div>
    """
  end

  defp pagination(%{page: %{total_pages: 1}} = assigns), do: ~H""
  defp pagination(assigns) do
    ~H"""
    <div class="m-pagination">
      <button phx-click="go_to_page" phx-value-n={@page.page_number - 1} disabled={@page.page_number == 1}>← Prev</button>
      <span>Page <%= @page.page_number %> of <%= @page.total_pages %></span>
      <button phx-click="go_to_page" phx-value-n={@page.page_number + 1} disabled={@page.page_number == @page.total_pages}>Next →</button>
    </div>
    """
  end
end
