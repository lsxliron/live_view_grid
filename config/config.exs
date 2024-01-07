import Config

config :tailwind, version: "3.3.2", default: [
  args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/live_view_grid.css
  ),
  cd: Path.expand("../assets", __DIR__)
]

config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outfile=../priv/static/live_view_grid.js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

  config :logger, :console,
  format: "$time [$level] [$metadata] $message\n",
  metadata: [:request_id, :mfa, :file, :line],
  level: :debug

import_config "#{config_env()}.exs"
