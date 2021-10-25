defmodule Mobilizon.GraphQL.Schema.AddressType do
  @moduledoc """
  Schema representation for Address
  """
  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.Place

  @desc """
  An place object
  """
  object :place do
    field(:geom, :point, description: "The geocoordinates for the point where this place is")
    field(:name, :string, description: "The place name")

    field(:events, :paginated_event_list,
      description: "The list of events on this place",
      resolve: &Place.events/3
    )

    field(:groups, :paginated_group_list,
      description: "The list of groups on this place",
      resolve: &Place.groups/3
    )
  end

  object :places_queries do
    @desc "Get trending places"
    field :trending_places, :paginated_place_list do
      arg(:query, :string)

      arg(:locale, :string,
        default_value: "en",
        description: "The user's locale. Geocoding backends will make use of this value."
      )

      arg(:page, :integer,
        default_value: 1,
        description: "The page in the paginated search results list"
      )

      arg(:limit, :integer, default_value: 10, description: "The limit of search places per page")

      resolve(&Place.search/3)
    end
  end
end
