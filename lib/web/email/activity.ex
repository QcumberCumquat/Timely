defmodule Mobilizon.Web.Email.Activity do
  @moduledoc """
  Handles emails sent about activity notifications.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Config
  alias Mobilizon.Web.{Email, Gettext}

  @spec direct_activity(String.t(), list(), String.t()) ::
          Bamboo.Email.t()
  def direct_activity(
        email,
        activities,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Activity notification for %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:subject, subject)
    |> assign(:activities, Enum.take(activities, 10))
    |> assign(:total_number_activities, length(activities))
    |> render(:email_direct_activity)
  end
end
