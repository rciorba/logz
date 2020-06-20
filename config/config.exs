use Mix.Config

config :logger, :console,
    device: :standard_error

config :elastix,
  json_codec: Logz.JiffyCodec,
  httpoison_options: [hackney: [pool: :elastix_pool]]
