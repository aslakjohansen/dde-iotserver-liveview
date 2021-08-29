defmodule DdeIotserverLiveview.Repo.Migrations.CreateDerivations do
  use Ecto.Migration

  def change do
    create table(:derivations) do
      add :stream_id, references(:streams), null: false
      add :analysis_id, references(:analyses), null: false
    end
    
    create unique_index(:derivations, [:stream_id, :analysis_id])
  end
end
