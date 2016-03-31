defmodule Logster.Plugs.Logger do
  @moduledoc """
  A plug for logging request information in the format:

      method=GET path=/articles/some-article format=html controller=HelloPhoenix.ArticleController action=show params={"id":"some-article"} status=200 duration=0.402 state=set

  To use it, just plug it into the desired module.

      plug Logster.Plugs.Logger, log: :debug

  For Phoenix applications, replace `Plug.Logger` with `Logster.Plugs.Logger` in the `endpoint.ex` file:

      # plug Plug.Logger
      plug Logster.Plugs.Logger

  ## Options

    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
  """

  require Logger
  alias Plug.Conn

  def init(opts) do
    Keyword.get(opts, :log, :info)
  end

  def call(conn, level) do
    before_time = :os.timestamp()

    Conn.register_before_send(conn, fn conn ->
      Logger.log level, fn ->
        after_time = :os.timestamp()

        [
          formatted_info("method", conn.method),
          formatted_info("path", conn.request_path),
          formatted_phoenix_info(conn),
          formatted_info("params", conn.params |> Poison.encode!),
          formatted_info("status", conn.status |> Integer.to_string),
          formatted_info("duration", formatted_duration(before_time, after_time)),
          formatted_info("state", conn.state |> Atom.to_string, "")
        ]
      end
      conn
    end)
  end

  defp formatted_duration(before_time, after_time), do: :timer.now_diff(after_time, before_time) / 1000 |> Float.to_string(decimals: 3)

  defp formatted_phoenix_info(%{private: %{phoenix_format: format, phoenix_controller: controller, phoenix_action: action}}) do
    [
      formatted_info("format", format),
      formatted_info("controller", controller |> inspect),
      formatted_info("action", action |> Atom.to_string)
    ]
  end
  defp formatted_phoenix_info(_), do: []

  defp formatted_info(name, value, postfix \\ ?\s), do: [name, "=", value, postfix]
end
