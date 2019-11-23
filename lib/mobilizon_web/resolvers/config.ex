defmodule MobilizonWeb.Resolvers.Config do
  @moduledoc """
  Handles the config-related GraphQL calls.
  """

  alias Mobilizon.Config
  alias Geolix.Adapter.MMDB2.Record.{Country, Location}

  @doc """
  Gets config.
  """
  def get_config(_parent, _params, %{
        context: %{ip: ip}
      }) do
    geolix = Geolix.lookup(ip)

    country_code =
      case Map.get(geolix, :city) do
        %{country: %Country{iso_code: country_code}} -> String.downcase(country_code)
        _ -> nil
      end

    location =
      case Map.get(geolix, :city) do
        %{location: %Location{} = location} -> Map.from_struct(location)
        _ -> nil
      end

    {:ok,
     %{
       name: Config.instance_name(),
       registrations_open: Config.instance_registrations_open?(),
       demo_mode: Config.instance_demo_mode?(),
       description: Config.instance_description(),
       location: location,
       country_code: country_code,
       geocoding: %{
         provider: Config.instance_geocoding_provider(),
         autocomplete: Config.instance_geocoding_autocomplete()
       },
       maps: %{
         tiles: %{
           endpoint: Config.instance_maps_tiles_endpoint(),
           attribution: Config.instance_maps_tiles_attribution()
         }
       }
     }}
  end
end
