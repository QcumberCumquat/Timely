defmodule Mobilizon.Actors.Service.ResetPassword do
  @moduledoc false

  require Logger

  alias Mobilizon.{Mailer, Repo, Actors.User}
  alias Mobilizon.Email.User, as: UserEmail
  alias Mobilizon.Actors.Service.Tools

  @doc """
  Check that the provided token is correct and update provided password
  """
  @spec check_reset_password_token(String.t(), String.t()) :: tuple
  def check_reset_password_token(password, token) do
    with %User{} = user <- Repo.get_by(User, reset_password_token: token),
         {:ok, %User{} = user} <-
           Repo.update(
             User.password_reset_changeset(user, %{
               "password" => password,
               "reset_password_sent_at" => nil,
               "reset_password_token" => nil
             })
           ) do
      {:ok, user}
    else
      err ->
        {:error, :invalid_token}
    end
  end

  @doc """
  Send the email reset password, if it's not too soon since the last send
  """
  @spec send_password_reset_email(User.t(), String.t()) :: tuple
  def send_password_reset_email(%User{} = user, locale \\ "en") do
    with :ok <- Tools.we_can_send_email(user, :reset_password_sent_at),
         {:ok, %User{} = user_updated} <-
           Repo.update(
             User.send_password_reset_changeset(user, %{
               "reset_password_token" => Tools.random_string(30),
               "reset_password_sent_at" => DateTime.utc_now()
             })
           ) do
      mail =
        user_updated
        |> UserEmail.reset_password_email(locale)
        |> Mailer.deliver_later()

      {:ok, mail}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end