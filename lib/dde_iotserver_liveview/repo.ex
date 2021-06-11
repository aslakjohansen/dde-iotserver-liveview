defmodule DdeIotserverLiveview.Repo do
  use Ecto.Repo,
    otp_app: :dde_iotserver_liveview,
    adapter: Ecto.Adapters.Postgres
end
