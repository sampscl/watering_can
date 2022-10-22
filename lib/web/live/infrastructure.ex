defmodule Web.Live.Infrastructure do
  @moduledoc """
  Live view of infrastructure
  """
  use Web, :live_view
  require Logger

  def render(assigns) do
    ~H"""
    Current temperature: <%= @temperature %>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Web.PubSub, "infrastructure")
    end

    temperature = "one million degrees"
    {:ok, assign(socket, :temperature, temperature)}
  end

  def handle_info(%{topic: _topic, payload: _payload} = msg, socket) do
    Logger.debug(inspect(msg, pretty: true, limit: :infinity))
    {:noreply, socket}
  end
end
