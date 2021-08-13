defmodule DdeIotserverLiveview.Repo.Migrations.CreateStreams do
  use Ecto.Migration

  def change do
    create table(:streams) do
      add :device_id, :string, null: false
      add :sensor_id, :string, null: false
    end
  end
end
