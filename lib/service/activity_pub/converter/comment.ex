defmodule Mobilizon.Service.ActivityPub.Converter.Comment do
  @moduledoc """
  Comment converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events.Comment, as: CommentModel
  alias Mobilizon.Events.Event
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.{Converter, Convertible}
  alias Mobilizon.Service.ActivityPub.Converter.Utils, as: ConverterUtils

  require Logger

  @behaviour Converter

  defimpl Convertible, for: CommentModel do
    alias Mobilizon.Service.ActivityPub.Converter.Comment, as: CommentConverter

    defdelegate model_to_as(comment), to: CommentConverter
  end

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: {:ok, map} | {:error, any()}
  def as_to_model_data(object) do
    Logger.debug("We're converting raw ActivityStream data to a comment entity")
    Logger.debug(inspect(object))

    with {:ok, %Actor{id: actor_id}} <- ActivityPub.get_or_fetch_actor_by_url(object["actor"]),
         {:tags, tags} <- {:tags, ConverterUtils.fetch_tags(object["tag"])},
         {:mentions, mentions} <- {:mentions, ConverterUtils.fetch_mentions(object["tag"])} do
      Logger.debug("Inserting full comment")
      Logger.debug(inspect(object))

      data = %{
        text: object["content"],
        url: object["id"],
        actor_id: actor_id,
        in_reply_to_comment_id: nil,
        event_id: nil,
        uuid: object["uuid"],
        tags: tags,
        mentions: mentions
      }

      # We fetch the parent object
      Logger.debug("We're fetching the parent object")

      data =
        if Map.has_key?(object, "inReplyTo") && object["inReplyTo"] != nil &&
             object["inReplyTo"] != "" do
          Logger.debug(fn -> "Object has inReplyTo #{object["inReplyTo"]}" end)

          case ActivityPub.fetch_object_from_url(object["inReplyTo"]) do
            # Reply to an event (Event)
            {:ok, %Event{id: id}} ->
              Logger.debug("Parent object is an event")
              data |> Map.put(:event_id, id)

            # Reply to a comment (Comment)
            {:ok, %CommentModel{id: id} = comment} ->
              Logger.debug("Parent object is another comment")

              data
              |> Map.put(:in_reply_to_comment_id, id)
              |> Map.put(:origin_comment_id, comment |> CommentModel.get_thread_id())

            # Anything else is kind of a MP
            {:error, parent} ->
              Logger.debug("Parent object is something we don't handle")
              Logger.debug(inspect(parent))
              data
          end
        else
          Logger.debug("No parent object for this comment")

          data
        end

      {:ok, data}
    else
      err ->
        {:error, err}
    end
  end

  @doc """
  Make an AS comment object from an existing `Comment` structure.
  """
  @impl Converter
  @spec model_to_as(CommentModel.t()) :: map
  def model_to_as(%CommentModel{} = comment) do
    to =
      if comment.visibility == :public,
        do: ["https://www.w3.org/ns/activitystreams#Public"],
        else: [comment.actor.followers_url]

    object = %{
      "type" => "Note",
      "to" => to,
      "cc" => [],
      "content" => comment.text,
      "actor" => comment.actor.url,
      "attributedTo" => comment.actor.url,
      "uuid" => comment.uuid,
      "id" => comment.url,
      "tag" =>
        ConverterUtils.build_mentions(comment.mentions) ++ ConverterUtils.build_tags(comment.tags)
    }

    if comment.in_reply_to_comment do
      object |> Map.put("inReplyTo", comment.in_reply_to_comment.url || comment.event.url)
    else
      object
    end
  end
end
