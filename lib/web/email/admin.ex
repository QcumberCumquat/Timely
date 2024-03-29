defmodule Mobilizon.Web.Email.Admin do
  @moduledoc """
  Handles emails sent to admins.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix

  import Mobilizon.Web.Gettext

  alias Mobilizon.Config
  alias Mobilizon.Reports.Report
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Email

  @spec report(User.t(), Report.t()) :: Bamboo.Email.t()
  def report(%User{email: email} = user, %Report{} = report) do
    locale = Map.get(user, :locale, "en")
    Gettext.put_locale(locale)

    subject =
      gettext(
        "New report on Mobilizon instance %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:subject, subject)
    |> assign(:report, report)
    |> render(:report)
  end
end
