defmodule YourApp.Whatever do
  @moduledoc "This is the genserver example when you want to subscribe into arbitrage signal."
  use GenServer

  # Callbacks

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end


  @impl true
  def init(stack) do

    # --- put this to subscribe to arbitrage signal
    {:ok, _} = Registry.register(:monitrage_registry, "arbitrage_signal", []) 

    # --- put this to subscribe to know which pair is currently under scanning
    {:ok, _} = Registry.register(:monitrage_registry, "current_pair", [])     

    {:ok, stack}
  end

    # --- If you register to "arbitrage_signal" in init, you HAVE to implement following handler."
  @impl true
  def handle_info({:arbitrage_signal, result}, state) do

    # --- do whatever you want with the information
    IO.inspect("I found potential arbitrage!")
    IO.inspect(result)
    {:noreply, state}
  end

    # --- If you register to "current_pair" in init, you HAVE to implement following handler."
  @impl true
  def handle_info({:current_pair, result}, state) do

    # --- do whatever you want with the information
    IO.inspect("currently process #{result}")
    {:noreply, state}
  end    
end