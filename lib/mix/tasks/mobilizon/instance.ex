# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/mix/tasks/pleroma/instance.ex

defmodule Mix.Tasks.Mobilizon.Instance do
  @moduledoc """
  Generates a new config

  ## Usage
  ``mix mobilizon.instance gen [OPTION...]``

  If any options are left unspecified, you will be prompted interactively.

  ## Options

  - `-f`, `--force` - overwrite any output files
  - `-o PATH`, `--output PATH` - the output file for the generated configuration
  - `--output-psql PATH` - the output file for the generated PostgreSQL setup
  - `--domain DOMAIN` - the domain of your instance
  - `--instance-name INSTANCE_NAME` - the name of your instance
  - `--admin-email ADMIN_EMAIL` - the email address of the instance admin
  - `--dbhost HOSTNAME` - the hostname of the PostgreSQL database to use
  - `--dbname DBNAME` - the name of the database to use
  - `--dbuser DBUSER` - the user (aka role) to use for the database connection
  - `--dbpass DBPASS` - the password to use for the database connection
  """

  use Mix.Task

  alias Mix.Tasks.Mobilizon.Common

  @preferred_cli_env "prod"

  @shortdoc "Generates a new config"
  def run(["gen" | options]) do
    {options, [], []} =
      OptionParser.parse(
        options,
        strict: [
          force: :boolean,
          output: :string,
          output_psql: :string,
          domain: :string,
          instance_name: :string,
          admin_email: :string,
          dbhost: :string,
          dbname: :string,
          dbuser: :string,
          dbpass: :string,
          dbport: :integer
        ],
        aliases: [
          o: :output,
          f: :force
        ]
      )

    paths =
      [config_path, psql_path] = [
        Keyword.get(options, :output, "config/prod.secret.exs"),
        Keyword.get(options, :output_psql, "setup_db.psql")
      ]

    will_overwrite = Enum.filter(paths, &File.exists?/1)
    proceed? = Enum.empty?(will_overwrite) or Keyword.get(options, :force, false)

    if proceed? do
      [domain, port | _] =
        String.split(
          Common.get_option(
            options,
            :domain,
            "What domain will your instance use? (e.g mobilizon.org)"
          ),
          ":"
        ) ++ [443]

      name =
        Common.get_option(
          options,
          :instance_name,
          "What is the name of your instance? (e.g. Mobilizon)"
        )

      email =
        Common.get_option(
          options,
          :admin_email,
          "What's the address email will be send with?",
          "noreply@#{domain}"
        )

      dbhost =
        Common.get_option(options, :dbhost, "What is the hostname of your database?", "localhost")

      dbname =
        Common.get_option(
          options,
          :dbname,
          "What is the name of your database?",
          "mobilizon_prod"
        )

      dbuser =
        Common.get_option(
          options,
          :dbuser,
          "What is the user used to connect to your database?",
          "mobilizon"
        )

      dbpass =
        Common.get_option(
          options,
          :dbpass,
          "What is the password used to connect to your database?",
          :crypto.strong_rand_bytes(64) |> Base.url_encode64() |> binary_part(0, 64),
          "autogenerated"
        )

      listen_port =
        Common.get_option(
          options,
          :listen_port,
          "What port will the app listen to (leave it if you are using the default setup with nginx)?",
          4000
        )

      instance_secret = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)
      auth_secret = :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

      template_dir = Application.app_dir(:mobilizon, "priv") <> "/templates"

      result_config =
        EEx.eval_file(
          "#{template_dir}/config.template.eex",
          instance_domain: domain,
          instance_port: port,
          instance_email: email,
          instance_name: name,
          database_host: dbhost,
          database_name: dbname,
          database_port: Keyword.get(options, :dbport, 5432),
          database_username: dbuser,
          database_password: dbpass,
          version: Mobilizon.Mixfile.project() |> Keyword.get(:version),
          instance_secret: instance_secret,
          auth_secret: auth_secret,
          listen_port: listen_port
        )

      result_psql =
        EEx.eval_file(
          "#{template_dir}/setup_db.eex",
          database_name: dbname,
          database_username: dbuser,
          database_password: dbpass
        )

      Mix.shell().info(
        "Writing config to #{config_path}. You should rename it to .env.production, .env.dev or .env.test"
      )

      File.write(config_path, result_config)
      Mix.shell().info("Writing #{psql_path}.")
      File.write(psql_path, result_psql)

      Mix.shell().info(
        "\n" <>
          """
          To get started:
          1. Check the contents of the generated files.
          2. Run `sudo -u postgres psql -f #{Common.escape_sh_path(psql_path)} && rm #{
            Common.escape_sh_path(psql_path)
          }`.
          """
      )
    else
      Mix.shell().error(
        "The task would have overwritten the following files:\n" <>
          (will_overwrite |> Enum.map(&"- #{&1}\n") |> Enum.join("")) <>
          "Rerun with `-f/--force` to overwrite them."
      )
    end
  end
end
