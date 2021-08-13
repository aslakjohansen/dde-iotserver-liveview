defmodule DdeIotserverLiveview.Repo.Migrations.CreateDerivedTimeseries do
  use Ecto.Migration

  def change do
    create table(:derived_timeseries) do
      add :derivation_id, references(:derivations), null: false
      add :cluster_id, references(:clusters)
      add :period, :int
      add :index, :int
      add :value, :float
    end
  end
end
