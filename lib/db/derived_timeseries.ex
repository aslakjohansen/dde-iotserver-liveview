defmodule DB.DerivedTimeseries do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query

  schema "derived_timeseries" do
    belongs_to :derivation, DB.Derivation
#    belongs_to :cluster, DB.Cluster
    field :period, :integer
    field :index, :integer
    field :value, :float
  end
  
  def changeset(struct, params) do
    struct
    |> cast(params, [:period, :index, :value])
    |> assoc_constraint(:derivation)
#    |> assoc_constraint(:cluster)
#    |> unique_constraint([:derivation, :cluster])
  end
  
  def insert(derivation, period, index, value) do
#  def insert(derivation, cluster, period, index, value) do
    %DB.DerivedTimeseries{
#      derivation: derivation, cluster: cluster,
      derivation: derivation,
      period: period, index: index, value: value
    }
    |> changeset(%{})
    |> DB.Repo.insert(on_conflict: :nothing)
  end
end
