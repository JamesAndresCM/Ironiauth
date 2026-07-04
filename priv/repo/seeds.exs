alias Ironiauth.Accounts.{Role, User, UserRole, Membership}
alias Ironiauth.Management
alias Ironiauth.Repo

# Roles
Enum.each(Role.role_types(), fn {name, _} -> Repo.insert!(%Role{name: name}) end)

# Company open_car
{:ok, open_car} = Management.create_company(%{"name" => "open_car", "domain" => "opencar.com"})
IO.puts("open_car api_key: #{open_car.api_key}")

# Admin user
{:ok, admin} =
  %User{}
  |> User.changeset(%{
    "username" => "admin",
    "email" => "admin@opencar.com",
    "password" => "admin1234",
    "password_confirmation" => "admin1234"
  })
  |> Ecto.Changeset.put_change(:active, true)
  |> Repo.insert()

# Membership admin → open_car
Repo.insert!(%Membership{user_id: admin.id, company_id: open_car.id, status: "active"})

# Rol admin al user
{:ok, admin_role} = Ironiauth.Accounts.find_role_by_name(:admin)
Repo.insert!(%UserRole{user_id: admin.id, role_id: admin_role.id})

IO.puts("Admin creado: admin@opencar.com / admin1234")
IO.puts("Company uuid: #{open_car.uuid}")
