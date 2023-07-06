import Config

config :tailwind, version: "3.3.2", default: [
  args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/live_view_grid.css
  ),
  cd: Path.expand("../assets", __DIR__)
]
