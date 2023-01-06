defmodule TimezoneConverterWeb.Router do
  use TimezoneConverterWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TimezoneConverterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TimezoneConverterWeb do
    pipe_through :browser

    live "/", ConverterLive, :index
    live "/:cities", ConverterLive, :index
  end


  if Application.compile_env(:timezone_converter, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TimezoneConverterWeb.Telemetry
    end
  end
end
