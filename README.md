# Monitrage

## What is this?

Monitrage (stands for Monitor Arbitrage) is an Elixir library to scan multiple cryptocurrency exchanges for price differences for potential market arbitrage. Utilizing natural concurrency in elixir, we can gather bids and asks from each exchange's orderbook in parallel to calculate potential profit by buying from one exchange and sell it to another.

## How it worked?
Every one hour we will get the supported pair from each of exchanges. We shortlisted to get pair which supported by 2 or more exchanges. 

In another process, we cycle those pairs, each time we fetch order book from all supported exchange and calculate whether there are potential profitable transaction by finding the best offer (minimum ask and maximum bid). When we found it we will broadcast to another interested process (see installation & usage to learn how to subscribe). We put 1 second sleep between pair to avoid rate limit imposed by exchanges. This behaviour can be modified through config.


## Exchange Support
Currently this library support following exchanges:

- Tokenomy
- Indodax
- Binance
- Bitfinex
- Kucoin

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `monitrage` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:monitrage, "~> 0.1.0"}
  ]
end
```

Fetch with `mix deps.get`


### Subscribe to signal

Include `Monitrage.Scanner.start_link` in your supervisor children, usually in your `application.ex`

```elixir
    children = [
      {Monitrage.Scanner, []}
    ]
```

Now you can subscribe to the signal. We use `Registry` standard library for internal pubsub mechanism. So you can spin a new genserver, register itself to `:monitrage_registry` with key "arbitrage_signal", and create handle_info for incoming `:arbitrage_found` message. See the following example:

```elixir

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


``` 

inside the handler of `handle_info({:arbitrage_signal, result}, state)` you can do anything. Such as trigger your trading bot, do another filter based on your treshold, or broadcast to another party using websocket.


When we found a potential arbitrage, the result comes in following map structure:
```

%{
  all_prices: [
    binance: %{
      higest_bid: ["0.00000013", "2948537491.00000000"],
      lowest_ask: ["0.00000014", "1108410494.00000000"]
    },
    kucoin: %{
      higest_bid: ["0.0000001319", "10.5054"],
      lowest_ask: ["0.0000001374", "190836.8871"]
    },
    tokenomy: %{
      higest_bid: ["0.00000014", "3848.92857142"],
      lowest_ask: ["0.00000016", "256978.55790600"]
    }
  ],
  buy_from: :kucoin,
  buy_price: "0.00000013",
  profit: "0.00000001",
  sell_price: "0.00000014",
  sell_to: :tokenomy
}

```

#### Additional config

If you want to speed up the cycle between pairs, you can redusce the time between pair scan. The default is 1000 (1 second), you can make it faster by decrease the gap. But please remember it might pass rate limit throttle by some exchange. Generally 3 request per second is considered conservative, so put 300 to 400 is usually safe. To do that, put this config in your `config.exs` file.

```
 config :monitrage,
   sleep_between_pair: 1000
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/monitrage](https://hexdocs.pm/monitrage).

