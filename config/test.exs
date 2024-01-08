import Config

config :logger, :console,
  format: "$time [$level] [$metadata] $message\n",
  metadata: [:request_id, :mfa, :file, :line],
  level: :warning

config :live_view_grid, LiveViewGrid.Endpoint,
  url: [host: "localhost"],
  render_errors: [],
  pubsub_server: LiveViewGrid.PubSub,
  live_view: [signing_salt: "EzKahPJw"],
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "m6PrYCllcsRA5x2HbKtkvNSdTL62PNT9p9XvocqEE8uLg5/i+vDNTV2mrXsjWS09",
  server: false
