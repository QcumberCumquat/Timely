defmodule Mobilizon.Medias.Media do
  @moduledoc """
  Represents a media entity.
  """

  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, cast_embed: 2]

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Medias.File
  alias Mobilizon.Medias.Media.Metadata
  alias Mobilizon.Posts.Post

  @type t :: %__MODULE__{
          file: File.t(),
          metadata: Metadata.t(),
          actor: Actor.t()
        }

  @attrs [:actor_id]

  schema "medias" do
    embeds_one(:file, File, on_replace: :update)

    embeds_one(:metadata, Metadata, on_replace: :update)

    belongs_to(:actor, Actor)
    has_many(:event_picture, Event, foreign_key: :picture_id)
    many_to_many(:events, Event, join_through: "events_medias")
    has_many(:posts_picture, Post, foreign_key: :picture_id)
    many_to_many(:posts, Post, join_through: "posts_medias")
    many_to_many(:comments, Comment, join_through: "comments_medias")

    timestamps()
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = media, attrs) do
    media
    |> cast(attrs, @attrs)
    |> cast_embed(:file)
    |> cast_embed(:metadata)
  end
end
