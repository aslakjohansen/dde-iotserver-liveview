# DdeIotserverLiveview

Start shell in VM running the application:
```shell
iex -S mix
```

Various imports:
```elixir
import NaiveDateTime
import Ecto.Query
```

Insert a raw timeseries:
```elixir
DB.RawTimeseries.insert(DB.Stream.ensure("dev1", "sens3"), NaiveDateTime.from_gregorian_seconds(42), 42.0)
```

List stored raw timeseries:
```elixir
DB.Repo.all(Ecto.Query.from(DB.RawTimeseries))
```

Ensure an analysis:
```elixir
a1 = DB.Analysis.ensure("delme1")
a2 = DB.Analysis.ensure("delme2")
```

Ensure a stream:
```elixir
s = DB.Stream.ensure("deldevice", "delsensor")
```

Ensure a derivation:
```elixir
d1 = DB.Derivation.ensure(s, a1)
d2 = DB.Derivation.ensure(s, a2)
```

Ensure a derived timeseries value:
```elixir
dt = DB.DerivedTimeseries.insert(d1, 0, 0, 0.0)
```

