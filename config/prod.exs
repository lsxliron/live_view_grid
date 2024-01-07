import Config

config :logger, :console,
  format: "$time [$level] [$metadata] $message\n",
  metadata: [:request_id, :mfa, :file, :line],
  level: :info
