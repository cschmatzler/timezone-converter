defmodule TimezoneConverter.Timezones do
  @moduledoc """
  Domain methods for the Timezones context.
  """

  alias TimezoneConverter.Timezones.City
  alias TimezoneConverter.Repo

  import Ecto.Query

  @doc false
  @spec get_city(binary()) :: City.t() | nil
  def get_city(id) do
    Repo.get(City, id)
  end

  @doc """
  Searches the city database using fuzzy search.

  Uses trigrams to find matches, and Levenshtein distance to
  order results. The results are ordered according to that
  distance.
  """
  @spec search_city(String.t()) :: list(City.t())
  def search_city(query) do
    first_char = String.at(query, 0)

    from(c in City,
      # Only show matches where the first character is a match.
      where: ilike(c.name, ^"#{first_char}%"),
      # Shortcut for `SIMILARITY(?, ?)` with default threshhold.
      where: fragment("? % ?", c.name, ^query),
      # Order by Levensthein distance.
      order_by: fragment("LEVENSHTEIN(?, ?)", c.name, ^query)
    )
    |> Repo.all()
  end

  @doc """
  Parses a time string into a `DateTime` with timezone.

  Requires the input string to be of format `02:00`.
  Returns a `DateTime` with the parsed time and current date in the passed timezone.
  """
  @spec parse(String.t(), String.t()) :: {:ok, DateTime.t()} | :error
  def parse(string, client_timezone) do
    case Timex.parse(string, "%H:%M", :strftime) do
      {:ok, datetime} ->
        # `Timex.parse` returns a `NaiveDateTime`, and since we are only parsing the time
        # part, the date is set to `0000-01-01`. Since timezone conversion is heavily
        # date dependent (daylight savings, timezones changing over the year, ...), we are
        # replacing that date with the current one.
        time = NaiveDateTime.to_time(datetime)
        today = Timex.today(client_timezone)
        time_today = DateTime.new!(today, time, client_timezone)

        {:ok, time_today}

      _ ->
        :error
    end
  end

  @doc false
  @spec convert(DateTime.t(), String.t()) :: DateTime.t() | {:error, any()}
  def convert(time, timezone) do
    Timex.Timezone.convert(time, timezone)
  end
end
