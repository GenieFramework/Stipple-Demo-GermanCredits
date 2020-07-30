using Genie.Configuration, Logging

const config = Settings(
  server_port                     = 9000,
  server_host                     = "127.0.0.1",
  websockets_port                 = 9001,
  log_level                       = Logging.Info,
  log_to_file                     = false,
  server_handle_static_files      = true
)

ENV["JULIA_REVISE"] = "auto"