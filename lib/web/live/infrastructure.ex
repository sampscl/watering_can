defmodule Web.Live.Infrastructure do
  use Web, :live_view
  use Utils.Logger, id: :web

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
    log_debug(inspect(msg, pretty: true, limit: :infinity))
    {:noreply, socket}
  end
end
