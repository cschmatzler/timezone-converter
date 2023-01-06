defmodule TimezoneConverter.TimezonesTest do
  alias TimezoneConverter.Timezones
  alias TimezoneConverter.Timezones.City

  use TimezoneConverter.DataCase

  defp hamburg_fixture do
    %City{id: Ecto.UUID.autogenerate(), name: "Hamburg", timezone: "Europe/Berlin"}
    |> Repo.insert!()
  end

  defp tokyo_fixture do
    %City{id: Ecto.UUID.autogenerate(), name: "Tokyo", timezone: "Asia/Tokyo"}
    |> Repo.insert!()
  end

  setup do
    hamburg = hamburg_fixture()
    tokyo = tokyo_fixture()

    %{hamburg: hamburg, tokyo: tokyo}
  end

  describe "get_city/1" do
    test "returns city if exists", %{hamburg: hamburg} do
      assert %City{} = Timezones.get_city(hamburg.id)
    end

    test "returns nil if not exists" do
      refute Timezones.get_city(Ecto.UUID.autogenerate())
    end
  end

  describe "search_city/1" do
    test "returns a list of cities matching the query" do
      assert length(Timezones.search_city("Ham")) == 1
    end

    test "supports fuzzy searching" do
      assert length(Timezones.search_city("Hamurg")) == 1
    end

    test "returns empty list if no match" do
      assert Enum.empty?(Timezones.search_city("Lisbon"))
    end
  end

  describe "parse/2" do
    test "returns a `DateTime` a valid string" do
      assert {:ok, %DateTime{}} = Timezones.parse("20:00", "Etc/UTC")
    end

    test "returns an error for an incorrect string" do
      assert :error = Timezones.parse("aaa", "Etc/UTC")
    end

    test "returns a `DateTime` with today as the current date" do
      {:ok, datetime} = Timezones.parse("20:00", "Etc/UTC")

      assert datetime.year == Date.utc_today().year
      assert datetime.month == Date.utc_today().month
      assert datetime.day == Date.utc_today().day
    end

    test "returns a `DateTime` with the correct hour and minute" do
      {:ok, datetime} = Timezones.parse("20:00", "Etc/UTC")

      assert datetime.hour == 20
      assert datetime.minute == 0
    end
  end
end
