defmodule DB.Derivation do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query

  schema "derivations" do
#    add :stream_id, references(:streams)
#    add :analysis_id, references(:analyses)
    belongs_to :stream, DB.Stream
    belongs_to :analysis, DB.Analysis
  end
  
  def changeset(struct, params) do
    struct
    |> cast(params, [])
    |> assoc_constraint(:stream)
    |> assoc_constraint(:analysis)
    |> unique_constraint([:stream, :analysis])
  end
  
  def ensure(stream, analysis) do
    # make sure record exists
    %DB.Derivation{stream: stream, analysis: analysis}
    |> changeset(%{})
    |> DB.Repo.insert(on_conflict: :nothing)
    
    # look up record
    DB.Derivation
    |> Ecto.Query.where([s], s.stream_id==^stream.id)
    |> Ecto.Query.where([s], s.analysis_id==^analysis.id)
    |> Ecto.Query.first()
    |> DB.Repo.one()
  end
end
