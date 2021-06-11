defmodule DdeIotserverLiveviewWeb.PageController do
  use DdeIotserverLiveviewWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
