defmodule IroniauthWeb.ManageLive.GroupDetail do
  use IroniauthWeb, :live_view

  alias Ironiauth.Management
  alias Ironiauth.Accounts

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    company = socket.assigns.manage_company
    group = Management.get_group_preloaded!(String.to_integer(id))

    all_permissions = Management.list_permissions(company.id)
    all_users = Accounts.list_users_for_company(company.id)

    group_permission_ids = Enum.map(group.permissions, & &1.id)
    group_user_ids = Enum.map(group.users, & &1.id)

    available_permissions = Enum.reject(all_permissions, &(&1.id in group_permission_ids))
    available_users = Enum.reject(all_users, &(&1.id in group_user_ids))

    {:ok,
     assign(socket,
       group: group,
       available_permissions: available_permissions,
       available_users: available_users,
       live_action: :group_detail
     )}
  end

  @impl true
  def handle_event("add_permission", %{"permission_id" => pid}, socket) do
    group = socket.assigns.group

    case Management.add_permission_to_group(%{group_id: group.id, permission_id: String.to_integer(pid)}) do
      {:ok, _} -> {:noreply, reload(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not add permission.")}
    end
  end

  def handle_event("remove_permission", %{"permission_id" => pid}, socket) do
    group = socket.assigns.group

    case Management.remove_permission_from_group(group.id, String.to_integer(pid)) do
      {:ok, _} -> {:noreply, reload(socket)}
      _ -> {:noreply, put_flash(socket, :error, "Could not remove permission.")}
    end
  end

  def handle_event("add_user", %{"user_id" => uid}, socket) do
    group = socket.assigns.group

    case Management.add_user_to_group(%{group_id: group.id, user_id: String.to_integer(uid)}) do
      {:ok, _} -> {:noreply, reload(socket)}
      {:error, _} -> {:noreply, put_flash(socket, :error, "Could not add user.")}
    end
  end

  def handle_event("remove_user", %{"user_id" => uid}, socket) do
    group = socket.assigns.group

    case Management.remove_user_from_group(group.id, String.to_integer(uid)) do
      {:ok, _} -> {:noreply, reload(socket)}
      _ -> {:noreply, put_flash(socket, :error, "Could not remove user.")}
    end
  end

  defp reload(socket) do
    company = socket.assigns.manage_company
    group = Management.get_group_preloaded!(socket.assigns.group.id)
    all_permissions = Management.list_permissions(company.id)
    all_users = Accounts.list_users_for_company(company.id)
    group_permission_ids = Enum.map(group.permissions, & &1.id)
    group_user_ids = Enum.map(group.users, & &1.id)

    assign(socket,
      group: group,
      available_permissions: Enum.reject(all_permissions, &(&1.id in group_permission_ids)),
      available_users: Enum.reject(all_users, &(&1.id in group_user_ids))
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="display:flex;align-items:center;gap:.75rem;margin-bottom:1.25rem">
      <.link navigate={~p"/manage/groups"} style="color:#64748b;font-size:.85rem">← Groups</.link>
      <h1 class="m-page-title" style="margin-bottom:0"><%= @group.name %></h1>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">

      <%# Permissions section %>
      <div class="m-card">
        <div class="m-card-title">Permissions (<%= length(@group.permissions) %>)</div>

        <%= if @group.permissions == [] do %>
          <div class="m-empty">No permissions assigned.</div>
        <% else %>
          <table class="m-table">
            <tbody>
              <%= for perm <- @group.permissions do %>
                <tr>
                  <td><span class="m-tag"><%= perm.name %></span></td>
                  <td style="text-align:right">
                    <button
                      phx-click="remove_permission"
                      phx-value-permission_id={perm.id}
                      class="m-btn m-btn-sm m-btn-danger"
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>

        <%= if @available_permissions != [] do %>
          <hr class="m-divider" />
          <div class="m-label" style="margin-bottom:.5rem">Add permission</div>
          <div style="display:flex;flex-wrap:wrap;gap:.4rem">
            <%= for perm <- @available_permissions do %>
              <button
                phx-click="add_permission"
                phx-value-permission_id={perm.id}
                class="m-btn m-btn-ghost m-btn-sm"
              >
                + <%= perm.name %>
              </button>
            <% end %>
          </div>
        <% end %>
      </div>

      <%# Users section %>
      <div class="m-card">
        <div class="m-card-title">Members (<%= length(@group.users) %>)</div>

        <%= if @group.users == [] do %>
          <div class="m-empty">No users in this group.</div>
        <% else %>
          <table class="m-table">
            <tbody>
              <%= for user <- @group.users do %>
                <tr>
                  <td><%= user.email %></td>
                  <td style="text-align:right">
                    <button
                      phx-click="remove_user"
                      phx-value-user_id={user.id}
                      class="m-btn m-btn-sm m-btn-danger"
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>

        <%= if @available_users != [] do %>
          <hr class="m-divider" />
          <div class="m-label" style="margin-bottom:.5rem">Add user</div>
          <table class="m-table">
            <tbody>
              <%= for user <- @available_users do %>
                <tr>
                  <td style="font-size:.8rem"><%= user.email %></td>
                  <td style="text-align:right">
                    <button
                      phx-click="add_user"
                      phx-value-user_id={user.id}
                      class="m-btn m-btn-sm"
                    >
                      Add
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% end %>
      </div>

    </div>
    """
  end
end
