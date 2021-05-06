defmodule Mobilizon.Service.Notifier.Email do
  @moduledoc """
  Email notifier
  """
  alias Mobilizon.Activities.Activity
  alias Mobilizon.{Config, Users}
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Service.Notifier.Email
  alias Mobilizon.Users.{NotificationPendingNotificationDelay, Setting, User}
  alias Mobilizon.Web.Email.Activity, as: EmailActivity
  alias Mobilizon.Web.Email.Mailer

  @behaviour Notifier

  @impl Notifier
  def ready? do
    Config.get(__MODULE__, :enabled)
  end

  @impl Notifier
  def send(%User{} = user, %Activity{} = activity, options) do
    Email.send(user, [activity], options)
  end

  @impl Notifier
  def send(%User{email: email, locale: locale} = user, activities, options)
      when is_list(activities) do
    if can_send?(user) do
      email
      |> EmailActivity.direct_activity(activities, Keyword.put(options, :locale, locale))
      |> Mailer.send_email()

      save_last_notification_time(user)
      {:ok, :sent}
    else
      {:ok, :skipped}
    end
  end

  @type notification_type ::
          :group_notifications
          | :notification_pending_participation
          | :notification_pending_membership

  @spec user_notification_delay(User.t(), notification_type()) ::
          NotificationPendingNotificationDelay.t()
  defp user_notification_delay(%User{} = user, type \\ :group_notifications) do
    Map.from_struct(user.settings)[type]
  end

  @spec can_send?(User.t()) :: boolean()
  defp can_send?(%User{settings: %Setting{last_notification_sent: last_notification_sent}} = user) do
    last_notification_sent_or_default = last_notification_sent || DateTime.utc_now()
    notification_delay = user_notification_delay(user)
    diff = DateTime.diff(DateTime.utc_now(), last_notification_sent_or_default)

    cond do
      notification_delay == :none -> false
      is_nil(last_notification_sent) -> true
      notification_delay == :direct -> true
      notification_delay == :one_hour -> diff >= 60 * 60
      notification_delay == :one_day -> diff >= 24 * 60 * 60
    end
  end

  @spec save_last_notification_time(User.t()) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  defp save_last_notification_time(%User{id: user_id}) do
    attrs = %{user_id: user_id, last_notification_sent: DateTime.utc_now()}

    case Users.get_setting(user_id) do
      nil ->
        Users.create_setting(attrs)

      %Setting{} = setting ->
        Users.update_setting(setting, attrs)
    end
  end
end
