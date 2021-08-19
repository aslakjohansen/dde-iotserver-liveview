defmodule DB.Stream do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query

  schema "streams" do
    field :device_id, :string
    field :sensor_id, :string
  end
  
  def changeset(struct, params) do
    struct
    |> cast(params, [:device_id, :sensor_id])
    |> validate_required([:device_id, :sensor_id])
    |> validate_length(:device_id, min: 1)
    |> validate_length(:sensor_id, min: 1)
    |> unique_constraint([:device_id, :sensor_id])
  end
  
  def ensure(device_id, sensor_id) do
    %DB.Stream{device_id: device_id, sensor_id: sensor_id}
    |> changeset(%{})
    |> DB.Repo.insert(on_conflict: :nothing)
    
    DB.Stream
    |> Ecto.Query.where([s], s.device_id==^device_id)
    |> Ecto.Query.where([s], s.sensor_id==^sensor_id)
    |> Ecto.Query.first()
    |> DB.Repo.one()
  end
end
