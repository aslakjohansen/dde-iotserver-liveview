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
    stream_id = Map.get(payload, "DeviceID") <> ":" <> Map.get(payload, "SensorID")
    
    # make sure fanout structure is in place
    generator = fn ->
      Enum.into(Enum.map(@analyses, fn {name, mod} ->
        {:ok, pid} = mod.start(stream_id)
        {name, {mod, pid}}
      end), %{})
    end
    table = Map.put_new_lazy(table, stream_id, generator)
    
    consumers = Map.get(table, stream_id)
    Enum.map(consumers, fn {_, {mod, pid}} -> mod.consume(pid, payload) end)
    {:noreply, {table}}
  end
  
end

