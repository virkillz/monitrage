defmodule Monitrage do
  @moduledoc """
  Documentation for Monitrage.
  """

@supported_exchange [
      binance: Monitrage.Binance,
      bitfinex: Monitrage.Bitfinex,
      indodax: Monitrage.Indodax,
      kucoin: Monitrage.Kucoin,
      tokenomy: Monitrage.Tokenomy
    ]

  @doc """
  Return the list of supported exchange

  """
  def supported_exchange do
    @supported_exchange
    |> Keyword.keys
  end

  def get_link(exchange, symbol) when is_atom(exchange) do

    if Keyword.has_key?(@supported_exchange, exchange) do
      # call function fetch_available_coin
      apply(@supported_exchange[exchange], :get_link_symbol, [symbol])
    else
      {:error, "Exchange is not supported"}
    end
  end


  @doc """
  Get list of available pairs from all exchange.

  """
  def list_supported_pairs do
    list_all_pairs_unique()
  end

  @doc """
  Get list of available pairs from certain exchange.

  """
  def list_supported_pairs(exchange) when is_atom(exchange) do

    if Keyword.has_key?(@supported_exchange, exchange) do
      # call function fetch_available_coin
      apply(@supported_exchange[exchange], :fetch_available_coins, [])
    else
      {:error, "Exchange is not supported"}
    end
  end

  @doc """
  Start scanning loop of all pair to get best price.

  """
  def start_link do
    IO.puts("Start scanning...")
    Monitrage.AvailableMarket.start_link([])
    cycle_target = list_prime_market()

    cycle_target
    |> Enum.shuffle()
    |> execute_loop()
  end

  @doc """
  Funtion to get best price by calling api

  """
  def fetch_best_prices(symbol) do
    available_exchanges = available_at(symbol)

    available_exchanges
    |> Enum.map(&{&1, Task.async(fn -> apply(@supported_exchange[&1], :best_offer, [symbol]) end)})
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

  @doc """
  Return all exchange with the list of supported market.

  """
  def list_supported_market do

    @supported_exchange
    |> Keyword.keys()
    |> Enum.map(&{&1, Task.async(fn -> apply(@supported_exchange[&1], :list_available_coins, []) end)})
    |> Enum.map(fn {k, v} -> {k, Task.await(v)} end)
    |> Enum.into(%{})
  end

  # ==================== implementation ===================

  # combine all available pairs
  defp list_all_pairs_duplicate do
    available_market = Monitrage.AvailableMarket.all()

    available_market
    |> Enum.map(fn {_k, v} -> v end)
    |> List.flatten()
  end

  # get all unique pairs
  defp list_all_pairs_unique do
    pairs = list_all_pairs_duplicate()

    pairs |> Enum.uniq()
  end

  # recurtion to keep looping
  defp execute_loop([]) do
    start_link()
  end

  defp execute_loop([h | t]) do
    case analyze_best_prices(h) do
      {:profit, result} ->
        # Replace this into broadcast channel or pubsub
        # IO.inspect(h)
        IO.puts(
          "trade #{h} from #{result.buy_from} with price #{result.buy_price} then sell to #{
            result.sell_to
          } with price #{result.sell_price} and get #{result.profit} profit"
        )

      _ ->
        :nothing
    end

    # wait one second to avoid throttle
    :timer.sleep(1000)
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

  def rawize(float) do
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
