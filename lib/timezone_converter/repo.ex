defmodule TimezoneConverter.Repo do
  use Ecto.Repo,
    otp_app: :timezone_converter,
    adapter: Ecto.Adapters.Postgres
end
