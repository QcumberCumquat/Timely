import Config

config :mobilizon, Mobilizon.Web.Endpoint,
  http: [
    port: String.to_integer(System.get_env("MOBILIZON_INSTANCE_HOST_PORT", "4000"))
  ],
  url: [
    host: System.get_env("MOBILIZON_INSTANCE_HOST", "mobilizon.local"),
    port: String.to_integer(System.get_env("MOBILIZON_INSTANCE_HOST_PORT", "80")),
    scheme: "http"
  ],
  secret_key_base: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY_BASE", "changethis"),
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "dev.js",
      cd: Path.expand("../js", __DIR__)
    ]
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :mobilizon, Mobilizon.Web.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/index.html$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/web/(live|views)/.*(ex)$},
      ~r{lib/web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", level: :debug

config :mobilizon, Mobilizon.Service.Geospatial, service: Mobilizon.Service.Geospatial.Nominatim

config :mobilizon, Mobilizon.Web.Gettext, allowed_locales: ["fr", "en"]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :mobilizon, Mobilizon.Web.Email.Mailer, adapter: Bamboo.LocalAdapter

# Configure your database
config :mobilizon, Mobilizon.Storage.Repo,
  username: System.get_env("MOBILIZON_DATABASE_USERNAME", "mobilizon"),
  password: System.get_env("MOBILIZON_DATABASE_PASSWORD", "mobilizon"),
  database: System.get_env("MOBILIZON_DATABASE_DBNAME", "mobilizon_dev"),
  hostname: System.get_env("MOBILIZON_DATABASE_HOST", "localhost"),
  port: System.get_env("MOBILIZON_DATABASE_PORT", "5432"),
  pool_size: 10,
  show_sensitive_data_on_connection_error: true

config :mobilizon, :instance,
  name: System.get_env("MOBILIZON_INSTANCE_NAME", "Mobilizon"),
  hostname: System.get_env("MOBILIZON_INSTANCE_HOST", "Mobilizon"),
  email_from: System.get_env("MOBILIZON_INSTANCE_EMAIL"),
  email_reply_to: System.get_env("MOBILIZON_INSTANCE_EMAIL"),
  registrations_open: System.get_env("MOBILIZON_INSTANCE_REGISTRATIONS_OPEN") == "true",
  groups: true

config :mobilizon, Mobilizon.Web.Auth.Guardian,
  secret_key: System.get_env("MOBILIZON_INSTANCE_SECRET_KEY", "changethis")

# config :mobilizon, :activitypub, sign_object_fetches: false

config :mobilizon, Mobilizon.Web.Upload.Uploader.Local, uploads: "uploads"

config :mobilizon, :anonymous,
  reports: [
    allowed: true
  ]

config :mobilizon, :http_security,
  enabled: true,
  sts: false,
  sts_max_age: 31_536_000,
  csp_policy: [
    script_src: ["localhost:3000"],
    style_src: [],
    connect_src: [],
    font_src: [],
    img_src: ["*.tile.openstreetmap.org"],
    manifest_src: [],
    media_src: [],
    object_src: [],
    frame_src: [],
    frame_ancestors: []
  ],
  referrer_policy: "same-origin"
