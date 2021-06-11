defmodule Receiver.Mqtt do
  use Tortoise.Handler

#  def main(_args \\ []) do
  def start_link(_opts) do
    args = "mqtt_config.json"
    |> File.read!()
    |> Jason.decode!()
    
    {:ok, _logger_pid, dispatcher_pid} = 
    args
    |> parse_args()
    |> startup()
    
#    case success do
#      {:ok} ->
#        IO.puts("success")
#      {_} ->
#        IO.puts("failure")
#    end
    
    IO.gets "Working... To finish hit <Enter>."
    
#    {:ok, args}
    {:ok, dispatcher_pid}
  end
  

  defp parse_args(args) do
    {opts, params, _} =
      args
      |> OptionParser.parse(switches: [silent: :boolean])
    
    {opts, params}
  end
  
  defp startup({opts, params}) do
    case {opts, params} do
      {_, [host, port, client_id, username, password, filename]} ->
        {:ok, logger_pid} = Receiver.Logger.start(filename)
        IO.puts("Logging to "<>filename)
        
        IO.puts("Connecting to #{username}:#{password}@#{host}:#{port} as client #{client_id}")
        {:ok, dispatcher_pid} = Receiver.Dispatch.start()
        state = [logger: logger_pid, dispatcher: dispatcher_pid]
        Tortoise.Supervisor.start_child(
          client_id: client_id,
          handler: {Receiver.Mqtt, state},
          server: {Tortoise.Transport.Tcp, host: host, port: String.to_integer(port)},
          subscriptions: [{"#", 0}],
          user_name: username,
          password: password
        )
        
        {:ok, logger_pid, dispatcher_pid}
      _ ->
        {:error}
    end
  end
  
  def connection(status, state) do
    case status do
      :up -> "Connected"
      _   -> "Othernected"
    end
    |> IO.puts()
    {:ok, state}
  end
  
  def handle_message(topic, payload, state) do
    logger     = state[:logger]
    dispatcher = state[:dispatcher]
    time = DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
    Receiver.Logger.log(logger, time, topic, payload)
    Receiver.Dispatch.dispatch(dispatcher, topic, payload)
    {:ok, state}
  end
  
  def subscription(_status, _topic_filter, state) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

end
