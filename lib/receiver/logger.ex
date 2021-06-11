defmodule Receiver.Logger do
  use GenServer
  
  # behaviour functions
  
  def start(filename) do
    GenServer.start(__MODULE__, filename)
  end
  
  def log(pid, time, topic, payload) do
    GenServer.cast(pid, {:log, time, topic, payload})
  end
  
  # callback functions
  
  @impl GenServer
  def init(filename) do
    {:ok, file} = File.open(filename, [:append])
    {:ok, {file}}
  end
  
  @impl GenServer
  def handle_cast({:log, time, topic, payload}, {file}) do
    :ok = IO.binwrite(file, "#{time} #{topic} #{payload}\n")
    {:noreply, {file}}
  end
  
end

