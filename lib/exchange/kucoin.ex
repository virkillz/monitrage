defmodule Monitrage.Kucoin do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://openapi-v2.kucoin.com"

  @doc """
  Hello world.

  ## Examples

      iex> Monitrage.hello()
      :world

  """
  def hello do
    :world
  end

  def fetch_available_coins do
    case HTTPoison.get(@domain <> "/api/v1/symbols") do
      {:ok, %{body: body, status_code: 200}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => symbols}} ->
            {:ok,
             Enum.map(symbols, fn x ->
               "#{String.downcase(x["baseCurrency"])}_#{String.downcase(x["quoteCurrency"])}"
             end)}

          _err ->
            {:error, "Cannot decode json. The api return format might be changed."}
        end

      err ->
        err
    end
  end

  def get_link_symbol(monitrage_symbol) do
    [asset, base] = monitrage_symbol |> String.split("_")

    "https://www.kucoin.com/trade/" <> String.upcase(asset) <> "-" <> String.upcase(base)

  end

  def list_available_coins do
    case fetch_available_coins() do
      {:ok, result} -> result
      _ -> []
    end
  end

  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    String.upcase(base) <> "-" <> String.upcase(quoted)
  end

  def depth(symbol) do
    case HTTPoison.get(@domain <> "/api/v1/market/orderbook/level2_20?symbol=" <> symbol) do
      {:ok, %{body: body, status_code: 200}} -> Jason.decode(body)
      err -> err
    end
  end

  def best_offer(symbol) do
    case depth(symbol |> decode_symbol) do
      {:ok, %{"data" => %{"asks" => asks, "bids" => bids}}} ->
        higest_bid = List.first(bids)
        lowest_ask = List.first(asks)
        %{higest_bid: higest_bid, lowest_ask: lowest_ask}

      err ->
        err
    end
  end
end
