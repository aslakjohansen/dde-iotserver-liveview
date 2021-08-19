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
    |> cast(params, [:device_id, :sensor_id])
  end
end
