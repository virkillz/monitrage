defmodule Monitrage do
  @moduledoc """

  Monitrage is a library to help us scan crypto exchanges for profitable arbitrage. To use this library you need to ensure `Monitrage.AvailableMarket.start_link` is running. 

  This module should run without dependency toward any genserver being run.

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
