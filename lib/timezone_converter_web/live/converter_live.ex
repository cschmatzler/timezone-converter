defmodule TimezoneConverterWeb.ConverterLive do
  alias TimezoneConverter.Timezones

  use TimezoneConverterWeb, :live_view

  import Phoenix.HTML.Form

  @impl true
  def render(assigns) do
    ~H"""
    <div id="converter" phx-hook="LocalTimezone" class="space-y-12">
      <h1 class="text-3xl text-bold text-rose-800">Timezone converter</h1>
      <section>
        <span class="text-lg">Current local time: <%= format(@current_time) %></span>
      </section>
      <section>
        <h2 class="text-xl">Choose a time</h2>
        <span class="text-gray-500"><%= @client_timezone %>, Format: HH:mm</span>
        <.form :let={f} for={@changeset} as={:time} phx-change="update-time">
          <%= text_input(f, :time, class: "rounded-md px-5") %>
          <span phx-click="use-current-time" class="cursor-pointer ml-8 justify-center underline">
            Reset and use current time
          </span>
          <%= if @parse_error do %>
            <span class="block mt-3 text-red-600">Invalid format, using current time instead.</span>
          <% end %>
        </.form>
      </section>
      <section>
        <h2 class="text-xl">Your cities</h2>
        <%= if Enum.empty?(@cities) do %>
          Please add a city below!
        <% else %>
          <ul>
            <%= for city <- @cities do %>
              <div class="flex">
                <span class="basis-1/3"><%= city.name %></span>
                <span class="basis-2/6"><%= city.timezone %></span>
                <span class="basis-1/6">
                  <%= if @parse_error do %>
                    <%= Timezones.convert(@current_time, city.timezone) |> format() %>
                  <% else %>
                    <%= Timezones.convert(@selected_time, city.timezone) |> format() %>
                  <% end %>
                </span>
                <button phx-click="remove-city" phx-value-city={city.id} class="basis-1/6">
                  Remove
                </button>
              </div>
            <% end %>
          </ul>
        <% end %>
      </section>
      <section>
        <h2 class="text-xl">Add a city</h2>
        <.form :let={f} for={:cities} phx-change="search">
          <%= text_input(f, :query, class: "rounded-lg px-5") %>
        </.form>
        <ol class="space-x-4 mt-6">
          <%= for result <- @city_search_results do %>
            <button
              phx-click="add-city"
              phx-value-city={result.id}
              class="bg-gray-200 px-4 py-2 rounded-lg"
            >
              <%= result.name %>
            </button>
          <% end %>
        </ol>
      </section>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # This is admittedly hella inefficient, since we're creating roundtrips every
    # second. In a production-ready world, this should probably calculate seconds
    # to the next minute, set a timer for that initial sync at the full minute,
    # then set an interval to 60000.
    # This is good enough for this exercise, though.
    :timer.send_interval(1000, self(), :update_current_time)

    socket =
      socket
      # Temporary assignment until we receive the `mounted()` event from the client
      |> assign(:client_timezone, "Etc/UTC")
      |> assign_current_time("Etc/UTC")
      |> assign(:selected_time, Timex.now())
      |> assign(:parse_error, false)
      |> assign(:use_custom_time, false)
      |> assign(:city_search_results, [])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    cities =
      Map.get(params, "cities", "")
      |> String.split(",")
      # Cast to UUID
      |> Enum.map(&Ecto.UUID.cast(&1))
      # returning `{:ok, uuid} | :error`, so we filter out the errors
      |> Enum.reject(&(&1 == :error))
      # and get the UUID out of the tuple.
      |> Enum.map(&elem(&1, 1))
      |> Enum.map(&Timezones.get_city(&1))
      |> Enum.reject(&is_nil(&1))

    socket = assign(socket, :cities, cities)

    {:noreply, socket}
  end

  @impl true
  def handle_event("set-client-timezone", timezone, socket) do
    socket =
      socket
      |> assign(:client_timezone, timezone)
      |> assign_current_time(timezone)

    {:noreply, socket}
  end

  @impl true
  def handle_event("use-current-time", _payload, socket) do
    socket =
      socket
      |> assign_current_time()
      |> assign(:use_custom_time, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update-time", %{"time" => %{"time" => time}}, socket) do
    socket = assign(socket, :changeset, changeset(time))

    case Timezones.parse(time, socket.assigns.client_timezone) do
      {:ok, datetime} ->
        socket =
          socket
          |> assign(:parse_error, false)
          |> assign(:use_custom_time, true)
          |> assign(:selected_time, datetime)

        {:noreply, socket}

      _ ->
        socket =
          socket
          |> assign(:parse_error, true)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("search", %{"cities" => %{"query" => query}}, socket) do
    results = Timezones.search_city(query)
    socket = assign(socket, :city_search_results, results)

    {:noreply, socket}
  end

  @impl true
  def handle_event("add-city", %{"city" => city}, socket) do
    current_city_ids = socket.assigns.cities |> Enum.map(& &1.id)
    new_city_ids = [city | current_city_ids] |> Enum.uniq() |> Enum.join(",")

    socket = push_patch(socket, to: ~p"/#{new_city_ids}")

    {:noreply, socket}
  end

  def handle_event("remove-city", %{"city" => city}, socket) do
    new_city_ids =
      socket.assigns.cities
      |> Enum.reject(&(Map.values(&1) |> Enum.member?(city)))
      |> Enum.map(& &1.id)
      |> Enum.join(",")

    socket = push_patch(socket, to: ~p"/#{new_city_ids}")

    {:noreply, socket}
  end

  @impl true
  def handle_info(:update_current_time, socket) do
    socket =
      assign_current_time(
        socket,
        not socket.assigns.use_custom_time
      )

    {:noreply, socket}
  end

  defp assign_current_time(socket, update_changeset \\ true) do
    current_time_in_timezone = Timex.now(socket.assigns.client_timezone)

    socket = assign(socket, :current_time, current_time_in_timezone)

    socket =
      if update_changeset,
        do:
          socket
          |> assign(:changeset, changeset(format(current_time_in_timezone)))
          |> assign(:selected_time, current_time_in_timezone),
        else: socket

    socket
  end

  defp changeset(time) do
    {%{}, %{time: :string}}
    |> Ecto.Changeset.cast(%{time: time}, [:time])
  end

  defp format(time) do
    Timex.format!(time, "%H:%M", :strftime)
  end
end
