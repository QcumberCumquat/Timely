defmodule MobilizonWeb.Resolvers.Address do
  @moduledoc """
  Handles the comment-related GraphQL calls
  """
  require Logger
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial

  @doc """
  Search an address
  """
  @spec search(map(), map(), map()) :: {:ok, list(Address.t())}
  def search(_parent, %{query: query, locale: locale, page: _page, limit: _limit}, %{
        context: %{ip: ip}
      }) do
    geolix = Geolix.lookup(ip)

    country_code =
      case geolix do
        %{country: %{iso_code: country_code}} -> String.downcase(country_code)
        _ -> nil
      end

    addresses = Geospatial.service().search(query, lang: locale, country_code: country_code)

    {:ok, addresses}
  end

  @doc """
  Reverse geocode some coordinates
  """
  @spec reverse_geocode(map(), map(), map()) :: {:ok, list(Address.t())}
  def reverse_geocode(
        _parent,
        %{longitude: longitude, latitude: latitude, zoom: zoom, locale: locale},
        _context
      ) do
    addresses = Geospatial.service().geocode(longitude, latitude, lang: locale, zoom: zoom)

    {:ok, addresses}
  end
end
