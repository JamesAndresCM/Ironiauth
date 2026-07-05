defmodule IroniauthWeb.ManageLive.Permissions do
  use IroniauthWeb, :live_view

  alias Ironiauth.Management

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.manage_company
    page = Management.list_permissions_paginated(company.id, 1)
    {:ok, assign(socket, page: page, live_action: :permissions)}
  end

  @impl true
  def handle_event("create_permission", %{"name" => name, "description" => description}, socket) do
    company = socket.assigns.manage_company

    case Management.create_company_permissions(company, %{"name" => String.trim(name), "description" => description}) do
      {:ok, _} ->
        page = Management.list_permissions_paginated(company.id, 1)
        {:noreply, assign(socket, page: page)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not create permission. Name may already exist.")}
    end
  end

  def handle_event("delete_permission", %{"id" => id}, socket) do
    permission = Management.get_permission!(String.to_integer(id))

    case Management.delete_permission(permission) do
      {:ok, _} ->
        company = socket.assigns.manage_company
        page = Management.list_permissions_paginated(company.id, socket.assigns.page.page_number)
        {:noreply, assign(socket, page: page)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete permission.")}
    end
  end

  def handle_event("go_to_page", %{"n" => n}, socket) do
    company = socket.assigns.manage_company
    page = Management.list_permissions_paginated(company.id, String.to_integer(n))
    {:noreply, assign(socket, page: page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="m-page-title">Permissions</h1>

    <div class="m-card">
      <div class="m-card-title">Create permission</div>
      <p style="font-size:.8rem;color:#64748b;margin-bottom:.75rem">
        Format: <code style="background:#f1f5f9;padding:.1rem .3rem;border-radius:3px">resource#action</code>
        &nbsp;e.g. <code style="background:#f1f5f9;padding:.1rem .3rem;border-radius:3px">car#create</code>
      </p>
      <form phx-submit="create_permission" class="m-form">
        <div>
          <label class="m-label">Name</label>
          <input class="m-input" type="text" name="name" placeholder="car#create" required />
        </div>
        <div>
          <label class="m-label">Description (optional)</label>
          <input class="m-input" type="text" name="description" placeholder="Create cars" />
        </div>
        <button type="submit" class="m-btn">Create</button>
      </form>
    </div>

    <div class="m-card">
      <div class="m-card-title">All permissions (<%= @page.total_entries %>)</div>
      <%= if @page.entries == [] do %>
        <div class="m-empty">No permissions yet. Create one above.</div>
      <% else %>
        <table class="m-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Description</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <%= for perm <- @page.entries do %>
              <tr>
                <td><span class="m-tag"><%= perm.name %></span></td>
                <td style="color:#64748b;font-size:.85rem"><%= perm.description %></td>
                <td style="text-align:right">
                  <button
                    phx-click="delete_permission"
                    phx-value-id={perm.id}
                    data-confirm={"Delete permission '#{perm.name}'?"}
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
