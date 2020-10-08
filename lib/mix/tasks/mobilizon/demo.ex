defmodule Mix.Tasks.Mobilizon.Demo do
  @moduledoc """
  Generates a new demo user, using the credentials

  ## Usage
  ``mix mobilizon.demo new``
  """

  use Mix.Task

  alias Mobilizon.{Actors, Users}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Users.User

  @preferred_cli_env "prod"

  @shortdoc "Creates a demo user"
  def run(["new" | options]) do
    {options, [], []} =
      OptionParser.parse(
        options,
        strict: [
          force: :boolean
        ],
        aliases: [
          f: :force
        ]
      )

    Mix.Task.run("app.start")

    with {:demo_mode_enabled, true} <-
           {:demo_mode_enabled, Application.get_env(:mobilizon, :instance)[:demo]},
         :ok <- maybe_delete_current_demo_account(options),
         [email: email, password: password] <- Application.get_env(:mobilizon, :demo_mode),
         {:ok, %User{} = user} <-
           Users.register(%{
             email: email,
             password: password,
             role: :user,
             confirmed_at: DateTime.utc_now(),
             confirmation_sent_at: nil,
             confirmation_token: nil
           }),
         {:ok, %Actor{preferred_username: preferred_username} = _new_person} <-
           Actors.new_person(%{
             user_id: user.id,
             preferred_username: "demo",
             name: "Demo",
             summary: "I am a simple demo profile"
           }) do
      Mix.shell().info("""
        An user has been created with the following information:
          - email: #{user.email}
          - password: #{password}
          - username: #{preferred_username}
        The user will be prompted to create a new profile after login for the first time.
      """)
    else
      {:error, %Ecto.Changeset{errors: [email: _err]}} ->
        Mix.raise(
          "An user already exists with the following email address. Add -f if you want to recreate it."
        )

      {:error, %Ecto.Changeset{errors: errors}} ->
        Mix.shell().error(inspect(errors))
        Mix.raise("User has not been created because of the above reason.")

      err ->
        Mix.shell().error(inspect(err))
        Mix.raise("User has not been created because of an unknown reason.")
    end
  end

  defp maybe_delete_current_demo_account(options) do
    with true <- Keyword.get(options, :force, false),
         [email: email, password: _password] <- Application.get_env(:mobilizon, :demo_mode),
         {:ok, %User{} = user} <- Users.get_user_by_email(email),
         actors <- Users.get_actors_for_user(user),
         :ok <- Enum.each(actors, &delete_profile/1) do
      Users.delete_user(user, reserve_email: false)
    end

    :ok
  end

  defp delete_profile(actor) do
    Actors.perform(:delete_actor, actor, reserve_username: false)
  end
end
