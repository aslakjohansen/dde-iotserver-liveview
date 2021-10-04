defmodule Receiver.Analysis.Summary do
  use GenServer
  
#  @analyses [:max, "min", "count", "sum", "tdiffmax", "tdiffmin", "tdiffsum", "diffmax", "diffmin", "diffsum", "diffcount"]
  @analyses [:max, :min, :count, :sum, :tdiffmax, :tdiffmin, :tdiffsum, :diffmax, :diffmin, :diffsum, :diffcount]
  @week 1000000000*60*60*24*7
  @step 60*60
  @ns2step 1000000000*@step
  @offset 1000000000*60*60*24*3 # jan 1st 1970 was a thursday
  
  # helpers
  
  def analysis2derivation(analysis_name, stream) do
    analysis   = DB.Analysis.ensure(analysis_name)
    derivation = DB.Derivation.ensure(stream, analysis)
    {analysis_name, derivation}
  end
  
  def decode_timestamp(time) do
    offsat = time - @offset
    period = div(offsat, @week)
    index  = div(rem(offsat, @week), @ns2step)
    {period, index}
  end
  
  # behaviour functions
  
  def start(device_id, sensor_id, stream_id) do
    stream = DB.Stream.ensure(device_id, sensor_id) # not used
    
    
    derivations =
    @analyses
    |> Enum.map(fn name -> analysis2derivation(Atom.to_string(name), stream) end)
    |> Map.new()
    
    GenServer.start(__MODULE__, {device_id, sensor_id, stream_id, derivations})
  end
  
  def consume(pid, payload) do
    GenServer.cast(pid, {:consume, payload})
  end
  
  # callback functions
  
  @impl GenServer
  def init({device_id, sensor_id, stream_id, derivations}) do
    # spawn process that periodically pings :sample. Period from opts
    server_pid = self()
#    period = 3600/3
#    period = 60/3
    period = @step
    _sampler_pid = spawn(fn -> sampler(server_pid, period) end)
    
    {:ok, {device_id, sensor_id, stream_id, derivations, []}}
  end
  
  @impl GenServer
  def handle_cast({:consume, payload}, {device_id, sensor_id, stream_id, derivations, window}) do
    timestamp = parse_time(Map.get(payload, "TimeStamp"))
    value     = Map.get(payload, "Value")
    wentry = [t: timestamp, v: value / 1]
    _time = DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
#    :ok = IO.puts("consume #{stream_id} #{time} #{timestamp} -> #{value}\n")
    {:noreply, {device_id, sensor_id, stream_id, derivations, [wentry]++window}}
  end
  
  @impl GenServer
  def handle_cast({:sample}, {device_id, sensor_id, stream_id, derivations, window}) do
    :ok = IO.puts("sample #{stream_id}\n")
    time = (DateTime.utc_now() |> DateTime.to_unix(:nanosecond)) - 3600*1000000000
    {newwindow, result} = analyze(window, time, [], [], nil, stream_id)
    _time = DateTime.utc_now() |> DateTime.to_unix(:nanosecond)
#    IO.inspect(result, label: "Results [ #{stream_id} ] #{time} ")
    
    # insert in database
    {period, index} = decode_timestamp(time)
    result
    |> Enum.each(
      fn({name, value}) ->
        name = Atom.to_string(name)
        IO.puts("- foreach")
        IO.puts("  - #{name} #{value}")
        d = Map.fetch!(derivations, name)
#        IO.puts("  - #{d}")
        result = derivations
        |> Map.fetch!(name)
        |> DB.DerivedTimeseries.insert(period, index, value)
#        IO.puts("  - sample #{name} #{value} #{result}\n")
      end
    )
    
#    derivations
#    |> Map.fetch(:a)
#    |> DB.DerivedTimeseries.insert(period, index, value)
    
    {:noreply, {device_id, sensor_id, stream_id, derivations, newwindow}}
  end
  
  # private functions
  
  defp analyze([head | tail], threshold, context, diffcontext, last, stream_id) do
    [t: timestamp, v: value] = head
    
    # handle diff
    newdiffcontext = case last do
      [t: t2, v: v2] ->
        vdiff = v2-value
        tdiff = (t2-timestamp)/1
        diff = vdiff/tdiff
        if diffcontext==[] do
          [
            tdiffmax: tdiff,
            tdiffmin: tdiff,
            tdiffsum: tdiff,
            diffmax: diff,
            diffmin: diff,
            diffsum: diff,
            diffcount: 1.0,
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
          [max: value, min: value, count: 1.0, sum: value]++newdiffcontext
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
    IO.puts("sampler #{period}")
    :timer.sleep(period_ms)
    sampler(pid, period)
  end
  
end

