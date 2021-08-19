defmodule DdeIotserverLiveview.Repo.Migrations.CreateStreams do
  use Ecto.Migration

  def change do
    create table(:streams) do
      add :device_id, :string, null: false
      add :sensor_id, :string, null: false
    end
    
    create unique_index(:streams, [:device_id, :sensor_id])
#    create unique_index(:streams, [:device_id, :sensor_id], name: :stream_uniqueness_index)
  end
end
