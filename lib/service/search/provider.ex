defmodule Mobilizon.Service.Search.Provider do
  @moduledoc """
  Behaviour for a search provider
  """

  @doc """
  Returns a paginated list of events
  """
  @callback search(options :: Keyword.t()) :: Mobilizon.Storage.Page.t(Mobilizon.Events.Event.t())
end
