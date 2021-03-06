defmodule DB.RawTimeseries do
  use Ecto.Schema
  import Ecto.Changeset

  schema "raw_timeseries" do
    field :time, :naive_datetime
    field :value, :float
    belongs_to :stream, DB.Stream
  end
  
  def changeset(struct, params) do
    struct
    |> cast(params, [:time, :value])
    |> unique_constraint([:time])
#    |> cast_assoc(params, :stream)
  end
  
  def insert(stream, time, value) do
    %DB.RawTimeseries{stream: stream, time: time, value: value}
    |> changeset(%{})
    |> DB.Repo.insert()
  end
end
