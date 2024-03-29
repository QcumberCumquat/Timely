defmodule Mobilizon.GraphQL.Resolvers.Tag do
  @moduledoc """
  Handles the tag-related GraphQL calls
  """

  alias Mobilizon.{Events, Posts}
  alias Mobilizon.Events.{Event, Tag}
  alias Mobilizon.Posts.Post
  alias Mobilizon.Storage.Page

  @spec list_tags(any(), map(), Absinthe.Resolution.t()) :: {:ok, Page.t(Tag.t())}
  def list_tags(_parent, %{page: page, limit: limit} = args, _resolution) do
    filter = Map.get(args, :filter)
    tags = Mobilizon.Events.list_tags(filter, page, limit)

    {:ok, tags}
  end

  @doc """
  Retrieve the list of tags for an event

  From an event or a struct with an url
  """
  @spec list_tags_for_event(Event.t(), map(), Absinthe.Resolution.t()) :: {:ok, list(Tag.t())}
  def list_tags_for_event(%Event{id: id}, _args, _resolution) do
    {:ok, Events.list_tags_for_event(id)}
  end

  # TODO: Check that I'm actually used
  def list_tags_for_event(%{url: url}, _args, _resolution) do
    with %Event{id: event_id} <- Events.get_event_by_url(url) do
      {:ok, Events.list_tags_for_event(event_id)}
    end
  end

  @doc """
  Retrieve the list of tags for a post
  """
  @spec list_tags_for_post(Post.t(), map(), Absinthe.Resolution.t()) :: {:ok, list(Tag.t())}
  def list_tags_for_post(%Post{id: id}, _args, _resolution) do
    {:ok, Posts.list_tags_for_post(id)}
  end

  #  @doc """
  #  Retrieve the list of related tags for a given tag ID
  #  """
  #  def get_related_tags(_parent, %{tag_id: tag_id}, _resolution) do
  #    with %Tag{} = tag <- Mobilizon.Events.get_tag!(tag_id),
  #         tags <- Mobilizon.Events.list_tag_neighbors(tag) do
  #      {:ok, tags}
  #    end
  #  end

  @doc """
  Retrieve the list of related tags for a parent tag
  """
  @spec get_related_tags(Tag.t(), map(), Absinthe.Resolution.t()) :: {:ok, list(Tag.t())}
  def get_related_tags(%Tag{} = tag, _args, _resolution) do
    {:ok, Events.list_tag_neighbors(tag)}
  end
end
