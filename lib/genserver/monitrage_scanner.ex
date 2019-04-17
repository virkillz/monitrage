defmodule Monitrage.Scanner do
  @moduledoc false
  use GenServer

  @name __MODULE__

  def start_link(_state) do

{:ok, _} =
  Registry.start_link(
    keys: :duplicate,
    name: :monitrage_registry,
    partitions: System.schedulers_online()
  )

    Monitrage.AvailableMarket.start_link([])
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  # API

  def all() do
    GenServer.call(@name, :all)
  end

  # Implementation

  @impl true
  def init(state) do

    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    # Do the work you desire here
    cycle_target = list_prime_market()

    cycle_target
    |> Enum.shuffle()
    |> execute_loop()

    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, state, state}
  end

  defp schedule_work() do
    # In 2 hours
    Process.send_after(self(), :work, 1000)
  end

  # ================================== internal function ==================

  def fetch_best_prices(symbol) do
    available_exchanges = available_at(symbol)
    supported_exchange = Monitrage.supported_exchange()

    available_exchanges
    |> Enum.map(&{&1, Task.async(fn -> apply(supported_exchange[&1], :best_offer, [symbol]) end)})
    |> Enum.map(fn {k, v} -> {k, Task.await(v)} end)
  end

  @doc """
  Get summary from best prices to calculate profit/loss

  """
  def analyze_best_prices(symbol) do
    list_price = fetch_best_prices(symbol)

    highest_bid =
      list_price
      |> Enum.map(fn {k, v} -> {k, float_string_to_raw(v.higest_bid)} end)

    lowest_ask =
      list_price
      |> Enum.map(fn {k, v} -> {k, float_string_to_raw(v.lowest_ask)} end)

    {sell_to, sell_price} = highest_bid |> find_highest()
    {buy_from, buy_price} = lowest_ask |> find_lowest()

    profit = sell_price - buy_price

    result = %{
      buy_from: buy_from,
      sell_to: sell_to,
      buy_price: raw_to_float_string(buy_price),
      sell_price: raw_to_float_string(sell_price),
      profit: raw_to_float_string(profit),
      all_prices: list_price
    }

    if profit > 0 do
      {:profit, result}
    else
      {:loss, result}
    end
  end

  @doc """
  Find the Exchange who support particular pair.

  """
  def available_at(symbol) do
    available_market = Monitrage.AvailableMarket.all()

    available_market
    |> Enum.filter(fn {_k, v} -> Enum.member?(v, symbol) end)
    |> Enum.map(fn {k, _v} -> k end)
  end

  # ==================== private function helper ===================

  # combine all available pairs
  defp list_all_pairs_duplicate do
    available_market = Monitrage.AvailableMarket.all()

    available_market
    |> Enum.map(fn {_k, v} -> v end)
    |> List.flatten()
  end

  # recurtion to keep looping
  defp execute_loop([]) do
  end

  defp execute_loop([h | t]) do
    # IO.puts("Try to search for #{h}")

      Registry.dispatch(:monitrage_registry, "current_pair", fn entries ->
        for {pid, _} <- entries, do: send(pid, {:current_pair, h})
      end)

    case analyze_best_prices(h) do
      {:profit, result} ->


        Registry.dispatch(:monitrage_registry, "arbitrage_signal", fn entries ->
          for {pid, _} <- entries, do: send(pid, {:arbitrage_signal, result})
        end)

        # IO.puts(
        #   "trade #{h} from #{result.buy_from} with price #{result.buy_price} then sell to #{
        #     result.sell_to
        #   } with price #{result.sell_price} and get #{result.profit} profit"
        # )

      _ ->
        :nothing
    end

    idle = Application.get_env(:monitrage, :sleep_between_pair, 1000)
    # wait one second to avoid throttle
    :timer.sleep(idle)
    execute_loop(t)
  end

  # at least supported by 2 or more exchange
  defp list_prime_market do
    all_pairs = list_all_pairs_duplicate()

    all_pairs
    |> Enum.group_by(& &1)
    |> Enum.filter(fn {_x, y} -> length(y) > 1 end)
    |> Enum.map(fn {x, _y} -> x end)
  end

  # def count_member(symbol, list) do
  #   Enum.count(list, fn x -> x == symbol end)
  # end

  defp float_string_to_raw(string) do
    string
    |> parse_price
    |> float_parse
    |> rawize
  end

  defp rawize(float) do
    Kernel.trunc(float * 1.0e8)
  end

  defp find_lowest(list_keyword) do
    lowest =
      list_keyword
      |> Keyword.values()
      |> Enum.sort()
      |> List.first()

    list_keyword
    |> Enum.filter(fn {_k, v} -> v == lowest end)
    |> List.first()
  end

  defp find_highest(list_keyword) do
    highest =
      list_keyword
      |> Keyword.values()
      |> Enum.sort(&(&1 >= &2))
      |> List.first()

    list_keyword
    |> Enum.filter(fn {_k, v} -> v == highest end)
    |> List.first()
  end

  defp raw_to_float_string(raw) do
    :erlang.float_to_binary(raw / 1.0e8, [{:decimals, 8}])
  end

  defp parse_price([price, _qty]) do
    price
  end

  defp float_parse(string) do
    {float, _} = Float.parse(string)
    float
  end
end
