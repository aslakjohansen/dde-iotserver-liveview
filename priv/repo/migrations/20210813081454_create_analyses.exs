defmodule DdeIotserverLiveview.Repo.Migrations.CreateAnalyses do
  use Ecto.Migration

  def change do
    create table(:analyses) do
      add :name, :string, null: false
    end
  end
end
