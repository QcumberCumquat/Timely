defmodule Mobilizon.Service.Search.SearchIndex do
  @moduledoc """
  Search provider for https://search.joinmobilizon.org
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.{Categories, Event, EventOptions}
  alias Mobilizon.Service.HTTP.GeospatialClient
  alias Mobilizon.Service.Search.Provider
  alias Mobilizon.Storage.Page
  import Plug.Conn.Query, only: [encode: 1]

  @behaviour Provider

  @default_endpoint "https://search.joinmobilizon.org"

  @events_api_endpoint "/api/v1/search/events"
  @groups_api_endpoint "/api/v1/search/groups"

  @default_options [
    start: 0,
    count: 10,
    distance: "10_km"
  ]

  # "?search=test&startDateMin=2022-04-21T16:08:32.675Z&boostLanguages[]=fr&boostLanguages[]=en&distance=10_km&sort=-match&start=0&count=5"

  @doc """
  Returns a paginated list of events
  """
  @impl Provider
  def search(options) do
    case fetch(options) do
      {:ok, %Tesla.Env{body: body, status: 200}} ->
        {:ok, transform_results(body, Keyword.get(options, :type, :events))}

      err ->
        require Logger
        Logger.error(inspect(err))
        {:error, :http_error}
    end
  end

  defp fetch(options) do
    @default_options
    |> Keyword.merge(options)
    |> build_url()
    |> GeospatialClient.get()
  end

  @spec transform_results(%{String.t() => list(map()) | non_neg_integer()}, atom()) ::
          Page.t(Event.t() | Actor.t())
  defp transform_results(%{"data" => data, "total" => total}, type) do
    %Page{
      total: total,
      elements:
        data
        |> Enum.sort(&(&1["score"] >= &2["score"]))
        |> Enum.map(fn element -> transform_result(element, type) end)
    }
  end

  @spec transform_result(map(), :events | :groups) :: Event.t() | Actor.t()
  defp transform_result(event, :events) do
    %Event{
      category: Categories.get_category(event["category"]),
      organizer_actor: transform_actor(event["creator"]),
      ends_on: event["endTime"],
      attributed_to: transform_actor(event["group"], :Group),
      id: event["id"],
      join_options: event["joinMode"],
      options: %EventOptions{
        is_online: event["isOnline"],
        maximum_attendee_capacity: event["maximumAttendeeCapacity"]
      },
      physical_address: transform_address(event["location"]),
      title: event["name"],
      publish_at: event["published"],
      begins_on: event["startTime"],
      status: String.downcase(event["status"]),
      tags: event["tags"],
      uuid: event["uuid"],
      url: event["url"]
    }
  end

  defp transform_result(group, :groups) do
    group = transform_actor(group)

    %Actor{
      group
      | type: :Group,
        physical_address: transform_address(group["location"])
    }
  end

  defp transform_actor(actor, type \\ :Person) do
    %Actor{
      type: type,
      id: actor["id"],
      url: actor["url"],
      summary: actor["description"],
      preferred_username: actor["name"],
      name: actor["displayName"],
      domain: actor["host"]
    }
  end

  defp transform_address(address) when is_map(address) do
    %Address{
      description: address["name"],
      geom: %Geo.Point{
        coordinates: {address["location"]["lon"], address["location"]["lat"]},
        srid: 4326
      },
      country: address["address"]["addressCountry"],
      locality: address["address"]["addressLocality"],
      region: address["address"]["addressRegion"],
      postal_code: address["address"]["postalCode"],
      street: address["address"]["streetAddress"]
    }
  end

  defp transform_address(_), do: nil

  @spec endpoint :: String.t()
  defp endpoint do
    :mobilizon
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:endpoint, @default_endpoint)
  end

  defp build_url(options) do
    {type, options} = Keyword.pop(options, :type, :events)
    "#{endpoint()}#{api_endpoint(type)}?#{encode(options)}"
  end

  defp api_endpoint(:events), do: @events_api_endpoint
  defp api_endpoint(:groups), do: @groups_api_endpoint
end
