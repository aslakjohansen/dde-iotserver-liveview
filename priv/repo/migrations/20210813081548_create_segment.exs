defmodule DdeIotserverLiveview.Repo.Migrations.CreateSegment do
  use Ecto.Migration

  def change do
    create table(:segment) do
      add :stream_id, references(:streams), null: false
      add :cluster_id, references(:clusters)
      add :beginning, :naive_datetime
      add :end, :naive_datetime
    end
  end
end
