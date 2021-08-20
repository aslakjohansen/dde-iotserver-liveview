defmodule Receiver.Analysis.Summary do
  use GenServer
  
  # behaviour functions
  
  def start(device_id, sensor_id, stream_id) do
    GenServer.start(__MODULE__, {device_id, sensor_id, stream_id})
  end
  
  def consume(pid, payload) do
    GenServer.cast(pid, {:consume, payload})
  end
  
  # callback functions
  
  @impl GenServer
  def init({device_id, sensor_id, stream_id}) do
    # spawn process that periodically pings :sample. Period from opts
    server_pid = self()
#    period = 3600/3
#    period = 60/3
    period = 60*60
    _sampler_pid = spawn(fn -> sampler(server_pid, period) end)
    
    {:ok, {device_id, sensor_id, stream_id, []}}
  end
  
  @impl GenServer
  def handle_cast({:consume, payload}, {device_id, sensor_id, stream_id, window}) do
    timestamp = parse_time(Map.get(payload, "TimeStamp"))
    value     = Map.get(payload, "Value")
    wentry = [t: timestamp, v: value]
    _time = DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
#    :ok = IO.puts("consume #{stream_id} #{time} #{timestamp} -> #{value}\n")
    {:noreply, {device_id, sensor_id, stream_id, [wentry]++window}}
  end
  
  @impl GenServer
  def handle_cast({:sample}, {device_id, sensor_id, stream_id, window}) do
#    :ok = IO.puts("sample #{stream_id}\n")
    time = (DateTime.utc_now() |> DateTime.to_unix(:nanosecond)) - 3600*1000000000
    {newwindow, _result} = analyze(window, time, [], [], nil, stream_id)
    _time = DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
#    IO.inspect(result, label: "Results [ #{stream_id} ] #{time} ")
    {:noreply, {device_id, sensor_id, stream_id, newwindow}}
  end
  
  # private functions
  
  defp analyze([head | tail], threshold, context, diffcontext, last, stream_id) do
    [t: timestamp, v: value] = head
    
    # handle diff
    newdiffcontext = case last do
      [t: t2, v: v2] ->
        vdiff = v2-value
        tdiff = t2-timestamp
        diff = vdiff/tdiff
        if diffcontext==[] do
          [
            tdiffmax: tdiff,
            tdiffmin: tdiff,
            tdiffsum: tdiff,
            diffmax: diff,
            diffmin: diff,
            diffsum: diff,
            diffcount: 1,
          ]
        else
          [
            tdiffmax: max(diffcontext[:tdiffmax], tdiff),
            tdiffmin: min(diffcontext[:tdiffmin], tdiff),
            tdiffsum:     diffcontext[:tdiffsum]+tdiff,
            diffmax: max(diffcontext[:diffmax], diff),
            diffmin: min(diffcontext[:diffmin], diff),
            diffsum:     diffcontext[:diffsum]+diff,
            diffcount: diffcontext[:diffcount]+1,
          ]
        end
      _ -> []
    end
    
    case timestamp do
      _ when timestamp>threshold ->
        newcontext = if context==[] do
          [max: value, min: value, count: 1, sum: value]++newdiffcontext
        else
          [
            max: max(context[:max], value),
            min: min(context[:min], value),
            sum:     context[:sum]+value,
            count: context[:count]+1,
          ]++newdiffcontext
        end
#        IO.inspect(newcontext, label: "analyze #{stream_id} [ht]-succ value=#{value}")
        {list, resultcontext} = analyze(tail, threshold, newcontext, newdiffcontext, head, stream_id)
        {[head]++list, resultcontext}
      _ ->
#        IO.inspect(context, label: "analyze #{stream_id} [ht]-fail ")
        {[], context}
    end
  end
  defp analyze([], _threshold, context, _diffcontext, _last, _stream_id) do
#    IO.inspect(context, label: "analyze #{stream_id} [] ")
    {[], context}
  end
  
  defp parse_time(ts) do
    {:ok, dt, _} = DateTime.from_iso8601(ts)
    DateTime.to_unix(dt, :nanosecond)
  end
  
  defp sampler(pid, period) do
    GenServer.cast(pid, {:sample})
    period_ms = 1000*period
#    IO.puts("sampler #{period}")
    :timer.sleep(period_ms)
    sampler(pid, period)
  end
  
end

