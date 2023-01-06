defmodule TimezoneConverter.Timezones.City do
  @moduledoc """
  Database schema for cities with their timezone information.

  The `timezone` field has to be in a valid TZ database format, such as `Europe/Berlin`.
  """
  use Ecto.Schema

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "cities" do
    field :name, :string
    field :timezone, :string
  end

  @type t :: %__MODULE__{
          id: binary(),
          name: String.t(),
          timezone: String.t()
        }
end
