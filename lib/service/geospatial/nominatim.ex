defmodule Mobilizon.Service.Geospatial.Nominatim do
  @moduledoc """
  [Nominatim](https://wiki.openstreetmap.org/wiki/Nominatim) backend.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Config

  require Logger

  @behaviour Provider

  @endpoint Application.get_env(:mobilizon, __MODULE__) |> get_in([:endpoint])
  @api_key Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])

  @impl Provider
  @doc """
  Nominatim implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(String.t(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    user_agent = Keyword.get(options, :user_agent, Config.instance_user_agent())
    headers = [{"User-Agent", user_agent}]
    url = build_url(:geocode, %{lon: lon, lat: lat}, options)
    Logger.debug("Asking Nominatim for geocode with #{url}")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, headers),
         {:ok, %{"features" => features}} <- Poison.decode(body) do
      features |> process_data() |> Enum.filter(& &1)
    else
      _ -> []
    end
  end

  @impl Provider
  @doc """
  Nominatim implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    user_agent = Keyword.get(options, :user_agent, Config.instance_user_agent())
    headers = [{"User-Agent", user_agent}]
    url = build_url(:search, %{q: q}, options)
    Logger.debug("Asking Nominatim for addresses with #{url}")

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <-
           HTTPoison.get(url, headers),
         {:ok, %{"features" => features}} <- Poison.decode(body) do
      features |> process_data() |> Enum.filter(& &1)
    else
      _ -> []
    end
  end

  @spec build_url(atom(), map(), list()) :: String.t()
  defp build_url(method, args, options) do
    limit = Keyword.get(options, :limit, 10)
    lang = Keyword.get(options, :lang, "en")
    endpoint = Keyword.get(options, :endpoint, @endpoint)
    country_code = Keyword.get(options, :country_code)
    zoom = Keyword.get(options, :zoom)
    api_key = Keyword.get(options, :api_key, @api_key)

    url =
      case method do
        :search ->
          "#{endpoint}/search?format=geocodejson&q=#{URI.encode(args.q)}&limit=#{limit}&accept-language=#{
            lang
          }&addressdetails=1&namedetails=1"

        :geocode ->
          url =
            "#{endpoint}/reverse?format=geocodejson&lat=#{args.lat}&lon=#{args.lon}&accept-language=#{
              lang
            }&addressdetails=1&namedetails=1"

          if is_nil(zoom), do: url, else: url <> "&zoom=#{zoom}"
      end

    url = if is_nil(country_code), do: url, else: "#{url}&countrycodes=#{country_code}"
    if is_nil(api_key), do: url, else: url <> "&key=#{api_key}"
  end

  defp process_data(features) do
    features
    |> Enum.map(fn %{
                     "geometry" => %{"coordinates" => coordinates},
                     "properties" => %{"geocoding" => geocoding}
                   } ->
      address = process_address(geocoding)
      %Address{address | geom: Provider.coordinates(coordinates)}
    end)
  end

  defp process_address(geocoding) do
    %Address{
      country: Map.get(geocoding, "country"),
      locality:
        Map.get(geocoding, "city") || Map.get(geocoding, "town") || Map.get(geocoding, "county"),
      region: Map.get(geocoding, "state"),
      description: description(geocoding),
      postal_code: Map.get(geocoding, "postcode"),
      type: Map.get(geocoding, "type"),
      street: street_address(geocoding),
      origin_id: "nominatim:" <> to_string(Map.get(geocoding, "osm_id"))
    }
  end

  @spec street_address(map()) :: String.t()
  defp street_address(body) do
    road =
      cond do
        Map.has_key?(body, "road") ->
          Map.get(body, "road")

        Map.has_key?(body, "street") ->
          Map.get(body, "street")

        Map.has_key?(body, "pedestrian") ->
          Map.get(body, "pedestrian")

        true ->
          ""
      end

    Map.get(body, "housenumber", "") <> " " <> road
  end

  @address29_classes ["amenity", "shop", "tourism", "leisure"]
  @address29_categories ["office"]

  @spec description(map()) :: String.t()
  defp description(body) do
    description = Map.get(body, "name")
    address = Map.get(body, "address")

    description =
      if Map.has_key?(body, "namedetails"),
        do: body |> Map.get("namedetails") |> Map.get("name", description),
        else: description

    description = if is_nil(description), do: street_address(body), else: description

    if (Map.get(body, "category") in @address29_categories or
          Map.get(body, "class") in @address29_classes) and Map.has_key?(address, "address29") do
      Map.get(address, "address29")
    else
      description
    end
  end
end
