# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/signature.ex

defmodule Mobilizon.Service.HTTPSignatures.Signature do
  @moduledoc """
  Adapter for the `HTTPSignatures` lib that handles signing and providing public keys to verify HTTPSignatures
  """

  @behaviour HTTPSignatures.Adapter

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.ActivityPub

  require Logger

  def key_id_to_actor_url(key_id) do
    %{path: path} =
      uri =
      key_id
      |> URI.parse()
      |> Map.put(:fragment, nil)

    uri =
      if is_nil(path) do
        uri
      else
        Map.put(uri, :path, String.trim_trailing(path, "/publickey"))
      end

    URI.to_string(uri)
  end

  @doc """
  Convert internal PEM encoded keys to public key format.
  """
  @spec prepare_public_key(String.t()) :: {:ok, tuple} | {:error, :pem_decode_error}
  def prepare_public_key(public_key_code) do
    case :public_key.pem_decode(public_key_code) do
      [public_key_entry] ->
        {:ok, :public_key.pem_entry_decode(public_key_entry)}

      _ ->
        {:error, :pem_decode_error}
    end
  end

  @doc """
  Gets a public key for a given ActivityPub actor ID (url).
  """
  @spec get_public_key_for_url(String.t()) ::
          {:ok, String.t()} | {:error, :actor_fetch_error | :pem_decode_error}
  def get_public_key_for_url(url) do
    with {:ok, %Actor{keys: keys}} <- ActivityPub.get_or_fetch_actor_by_url(url),
         {:ok, public_key} <- prepare_public_key(keys) do
      {:ok, public_key}
    else
      {:error, :pem_decode_error} ->
        Logger.error("Error while decoding PEM")

        {:error, :pem_decode_error}

      _ ->
        Logger.error("Unable to fetch actor, so no keys for you")

        {:error, :actor_fetch_error}
    end
  end

  def fetch_public_key(conn) do
    with %{"keyId" => kid} <- HTTPSignatures.signature_for_conn(conn),
         actor_id <- key_id_to_actor_url(kid),
         :ok <- Logger.debug("Fetching public key for #{actor_id}"),
         {:ok, public_key} <- get_public_key_for_url(actor_id) do
      {:ok, public_key}
    else
      e ->
        {:error, e}
    end
  end

  def refetch_public_key(conn) do
    with %{"keyId" => kid} <- HTTPSignatures.signature_for_conn(conn),
         actor_id <- key_id_to_actor_url(kid),
         :ok <- Logger.debug("Refetching public key for #{actor_id}"),
         {:ok, _actor} <- ActivityPub.make_actor_from_url(actor_id),
         {:ok, public_key} <- get_public_key_for_url(actor_id) do
      {:ok, public_key}
    else
      e ->
        {:error, e}
    end
  end

  def sign(%Actor{keys: keys} = actor, headers) do
    Logger.debug("Signing on behalf of #{actor.url}")
    Logger.debug("headers")
    Logger.debug(inspect(headers))

    with {:ok, key} <- prepare_public_key(keys) do
      HTTPSignatures.sign(key, actor.url <> "#main-key", headers)
    end
  end

  def generate_date_header(date \\ Timex.now("GMT")) do
    case Timex.format(date, "%a, %d %b %Y %H:%M:%S %Z", :strftime) do
      {:ok, date} ->
        date

      {:error, err} ->
        Logger.error("Unable to generate date header")
        Logger.debug(inspect(err))
        nil
    end
  end

  def generate_request_target(method, path), do: "#{method} #{path}"

  def build_digest(body) do
    "SHA-256=" <> (:crypto.hash(:sha256, body) |> Base.encode64())
  end
end
