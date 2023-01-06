defmodule TimezoneConverter.Repo.Migrations.Init do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION \"uuid-ossp\""
    execute "CREATE EXTENSION pg_trgm"
    execute "CREATE EXTENSION fuzzystrmatch"
  end

  def down do
    execute "DROP EXTENSION \"uuid-ossp\""
    execute "DROP EXTENSION pg_trgm"
    execute "DROP EXTENSION fuzzystrmatch"
  end
end
