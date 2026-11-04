import Config

config :ex_json_schema, SamplePhoenix.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 1234],
  server: true,
  secret_key_base: String.duplicate("a", 64)
