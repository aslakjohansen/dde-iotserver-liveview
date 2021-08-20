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

