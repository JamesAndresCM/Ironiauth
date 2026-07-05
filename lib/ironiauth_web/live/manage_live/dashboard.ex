defmodule IroniauthWeb.ManageLive.Dashboard do
  use IroniauthWeb, :live_view

  alias Ironiauth.Management

  @impl true
  def mount(_params, _session, socket) do
    company = socket.assigns.manage_company
    stats = Management.company_stats(company.id)
    {:ok, assign(socket, stats: stats, live_action: :dashboard)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="m-page-title">Dashboard</h1>

    <div class="m-stats">
      <div class="m-stat">
        <div class="m-stat-n"><%= @stats.users %></div>
        <div class="m-stat-l">Users</div>
      </div>
      <div class="m-stat">
        <div class="m-stat-n"><%= @stats.groups %></div>
        <div class="m-stat-l">Groups</div>
      </div>
      <div class="m-stat">
        <div class="m-stat-n"><%= @stats.permissions %></div>
        <div class="m-stat-l">Permissions</div>
      </div>
    </div>

    <div class="m-card">
      <div class="m-card-title">Quick access</div>
      <div style="display:flex;gap:.75rem;flex-wrap:wrap">
        <.link navigate={~p"/manage/groups"} class="m-btn m-btn-ghost">
          👥 Manage groups
        </.link>
        <.link navigate={~p"/manage/permissions"} class="m-btn m-btn-ghost">
          🔑 Manage permissions
        </.link>
        <.link navigate={~p"/manage/users"} class="m-btn m-btn-ghost">
          👤 View users
        </.link>
      </div>
    </div>
    """
  end
end
