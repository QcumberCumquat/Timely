defmodule Mobilizon.Service.Search.External do
  @moduledoc """
  Search providers manager
  """

  @doc """
  Queries the external search provider
  """
  def search(options) do
    provider().search(options)
  end

  @spec provider :: module()
  defp provider do
    :mobilizon
    |> Application.get_env(Mobilizon.Service.Search, [])
    |> Keyword.get(:extra_provider, Mobilizon.Service.Search.SearchIndex)
  end
end
