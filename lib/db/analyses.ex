defmodule DB.Analysis do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query

  schema "analyses" do
    field :name, :string
  end
  
  def changeset(struct, params) do
    struct
    |> cast(params, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1)
  end
  
  def ensure(name) do
    # make sure record exists
    %DB.Analysis{name: name}
    |> changeset(%{})
    |> DB.Repo.insert(on_conflict: :nothing)
    
    # look up record
    DB.Analysis
    |> Ecto.Query.where([s], s.name==^name)
    |> Ecto.Query.first()
    |> DB.Repo.one()
  end
end
