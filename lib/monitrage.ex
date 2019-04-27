defmodule Monitrage do
  @moduledoc """

  Monitrage is a library to help us scan crypto exchanges for profitable arbitrage. To use this library you need to ensure `Monitrage.AvailableMarket.start_link` is running. 

  This module should run without dependency toward any genserver being run.

  """

  @blacklisted_pair ["hot_btc", "hot_eth", "dat_eth", "dat_btc"]


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
  end

  def blacklist do
    @blacklisted_pair
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
  Return all exchange with the list of supported market.

  """
  def list_supported_market do
    @supported_exchange
    |> Keyword.keys()
    |> Enum.map(
      &{&1, Task.async(fn -> apply(@supported_exchange[&1], :list_available_coins, []) end)}
    )
    |> Enum.map(fn {k, v} -> {k, Task.await(v)} end)
    |> Enum.into(%{})
  end


  # def get_order_book(coin) when is_binary(coin) do
  # pair =
  #   if coin == "btc" do
  #     "btc_usdt"
  #   else
  #     coin <> "_btc"
  #   end
  # @supported_exchange
  #   |> Keyword.keys()
  #   |> Enum.map(
  #     &{&1, Task.async(fn -> apply(@supported_exchange[&1], :depth, [(apply(@supported_exchange[&1], :decode_symbol, [pair]))]) end)}
  #   )
  #   |> Enum.map(fn {k, v} -> {k, Task.await(v)} end)
  #   |> Enum.filter(fn {k,v} -> match?({:ok, _}, v) end)
  #   |> Enum.into(%{})
  # end

  def get_order_book(exchange, pair) when is_atom(exchange) do

    with true <- Keyword.has_key?(@supported_exchange, exchange),
         true <- String.contains?(pair, "_"),
         %{higest_bid: higest_bid, lowest_ask: lowest_ask} <- apply(Keyword.get(@supported_exchange, exchange), :best_offer, [pair])
    do
        if higest_bid == 0 or lowest_ask == nil do
          {:error, "Pair not supported or failed to fetch"}
        else
          {:ok, %{higest_bid: higest_bid, lowest_ask: lowest_ask, exchange: Atom.to_string(exchange), pair: pair}}
        end
    else
      _error -> {:error, "Exchange not supported or wrong pair format"}
    end

  end  

  def get_order_book(pair) when is_binary(pair) do
  @supported_exchange
    |> Keyword.keys()
    |> Enum.map(
      &{&1, Task.async(fn -> apply(@supported_exchange[&1], :best_offer, [pair]) end)}
    )
    |> Enum.map(fn {k, v} -> {k, Task.await(v)} end)
    |> Enum.filter(fn {k,v} -> not match?(%{higest_bid: 0, lowest_ask: nil}, v) end)  
    |> Enum.into(%{})
  end  

  def get_order_book(pair) do
    {:error, "invalid pair"}
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
end
