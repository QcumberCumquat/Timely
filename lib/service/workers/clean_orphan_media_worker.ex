defmodule Mobilizon.Service.Workers.CleanOrphanMediaWorker do
  @moduledoc """
  Worker to clean orphan media
  """

  use Oban.Worker, queue: "background"
  alias Mobilizon.Config
  alias Mobilizon.Service.CleanOrphanMedia

  @impl Oban.Worker
  def perform(%Job{}) do
    if Keyword.get(Config.instance_config(), :remove_orphan_uploads, false) and should_perform?() do
      CleanOrphanMedia.clean()
    end
  end

  @spec should_perform? :: boolean()
  defp should_perform? do
    case Cachex.get(:key_value, "last_media_cleanup") do
      {:ok, %DateTime{} = last_media_cleanup} ->
        default_grace_period = Config.get([:instance, :orphan_upload_grace_period_hours], 48)

        DateTime.compare(
          last_media_cleanup,
          DateTime.add(DateTime.utc_now(), default_grace_period * -3600)
        ) == :lt

      _ ->
        true
    end
  end
end
