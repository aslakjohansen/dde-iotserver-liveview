defmodule DdeIotserverLiveview.Repo.Migrations.CreateRawTimeseries do
  use Ecto.Migration

  def change do
    create table(:raw_timeseries) do
      add :stream_id, references(:streams), null: false
      add :time, :naive_datetime, null: false
      add :value, :float
    end
    
    create unique_index(:raw_timeseries, [:time])
  end
end
