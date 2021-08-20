defmodule Receiver.Dispatch do
  use GenServer
  
  @analyses %{summary: Receiver.Analysis.Summary}
  
  # behaviour functions
  
  def start() do
    GenServer.start(__MODULE__, nil)
  end
  
  def dispatch(pid, topic, payload) do
    GenServer.cast(pid, {:dispatch, topic, payload})
  end
  
  # callback functions
  
  @impl GenServer
  def init(_) do
    table = %{}
    {:ok, {table}}
  end
  
  @impl GenServer
  def handle_cast({:dispatch, _topic, payload}, {table}) do
    payload = Jason.decode!(payload)
    device_id = Map.get(payload, "DeviceID")
    sensor_id = Map.get(payload, "SensorID")
    stream_id = device_id <> ":" <> sensor_id
    time  = Map.get(payload, "TimeStamp") |> NaiveDateTime.from_iso8601!() |> NaiveDateTime.truncate(:second)
    value = Map.get(payload, "Value")
    
    # TODO: cache stream
    DB.Stream.ensure(device_id, sensor_id)
    |> DB.RawTimeseries.insert(time, value)
    
    # make sure fanout structure is in place
    generator = fn ->
      Enum.into(Enum.map(@analyses, fn {name, mod} ->
        {:ok, pid} = mod.start(device_id, sensor_id, stream_id)
        {name, {mod, pid}}
      end), %{})
    end
    table = Map.put_new_lazy(table, stream_id, generator)
    
    consumers = Map.get(table, stream_id)
    Enum.map(consumers, fn {_, {mod, pid}} -> mod.consume(pid, payload) end)
    {:noreply, {table}}
  end
  
end

