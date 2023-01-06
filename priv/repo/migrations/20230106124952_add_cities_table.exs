defmodule TimezoneConverter.Repo.Migrations.AddCitiesTable do
  use Ecto.Migration

  def change do
    create table("cities", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :timezone, :string
    end
  end
end
