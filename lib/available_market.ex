defmodule Monitrage.AvailableMarket do
  use GenServer

  @name __MODULE__

  def start_link(default) do
    GenServer.start_link(__MODULE__, default, name: @name)
  end

  # API

  def all() do
    GenServer.call(@name, :all)
  end

  # Implementation

  @impl true
  def init(_state) do
    init_state = Monitrage.list_supported_market()
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, init_state}
  end

  @impl true
  def handle_info(:work, _state) do
    # Do the work you desire here
    refresh_state = Monitrage.list_supported_market()
    # Reschedule once more
    schedule_work()
    {:noreply, refresh_state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  defp schedule_work() do
    # In 2 hours
    Process.send_after(self(), :work, 2 * 60 * 60 * 1000)
  end
end
