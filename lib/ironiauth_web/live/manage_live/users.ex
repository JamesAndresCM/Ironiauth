defmodule IroniauthWeb.ManageLive.Users do
  use IroniauthWeb, :live_view

  alias Ironiauth.Accounts

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.manage_company
    page = Accounts.list_users_for_company_paginated(company.id, 1)
    {:ok, assign(socket, page: page, live_action: :users)}
  end

  @impl true
  def handle_event("go_to_page", %{"n" => n}, socket) do
    company = socket.assigns.manage_company
    page = Accounts.list_users_for_company_paginated(company.id, String.to_integer(n))
    {:noreply, assign(socket, page: page)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="m-page-title">Users</h1>

    <div class="m-card">
      <div class="m-card-title">All users (<%= @page.total_entries %>)</div>
      <%= if @page.entries == [] do %>
        <div class="m-empty">No users in this company yet.</div>
      <% else %>
        <table class="m-table">
          <thead>
            <tr>
              <th>Email</th>
              <th>Username</th>
              <th>Groups</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <%= for user <- @page.entries do %>
              <tr>
                <td><%= user.email %></td>
                <td style="color:#64748b"><%= user.username %></td>
                <td>
                  <%= if user.user_groups == [] do %>
                    <span style="color:#94a3b8;font-size:.8rem">No groups</span>
                  <% else %>
                    <%= for ug <- user.user_groups do %>
                      <span class="m-tag"><%= ug.group.name %></span>
                    <% end %>
                  <% end %>
                </td>
                <td>
                  <%= if user.active do %>
                    <span class="m-tag m-tag-green">Active</span>
                  <% else %>
                    <span class="m-tag">Inactive</span>
                  <% end %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <.pagination page={@page} />
      <% end %>
    </div>

    <div class="m-card" style="font-size:.8rem;color:#64748b">
      To assign a user to a group, go to
      <.link navigate={~p"/manage/groups"} style="color:#4f46e5">Groups</.link>
      and open the group detail.
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
