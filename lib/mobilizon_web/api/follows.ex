defmodule MobilizonWeb.API.Follows do
  @moduledoc """
  Common API for following, unfollowing, accepting and rejecting stuff.
  """

  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Follower}
  alias Mobilizon.Service.ActivityPub
  alias Mobilizon.Service.ActivityPub.Activity

  require Logger

  def follow(%Actor{} = follower, %Actor{} = followed) do
    case ActivityPub.follow(follower, followed) do
      {:ok, activity, _} ->
        {:ok, activity}

      e ->
        Logger.warn("Error while following actor: #{inspect(e)}")
        {:error, e}
    end
  end

  def unfollow(%Actor{} = follower, %Actor{} = followed) do
    case ActivityPub.unfollow(follower, followed) do
      {:ok, activity, _} ->
        {:ok, activity}

      e ->
        Logger.warn("Error while unfollowing actor: #{inspect(e)}")
        {:error, e}
    end
  end

  def accept(%Actor{} = follower, %Actor{} = followed) do
    with %Follower{approved: false} = follow <-
           Actors.is_following(follower, followed),
         {:ok, %Activity{} = activity, %Follower{approved: true}} <-
           ActivityPub.accept(
             :follow,
             follow,
             %{approved: true}
           ) do
      {:ok, activity}
    else
      %Follower{approved: true} ->
        {:error, "Follow already accepted"}
    end
  end
end
