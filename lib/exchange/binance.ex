defmodule Monitrage.Binance do
  @moduledoc """
  Documentation for Monitrage.
  """

  @behaviour Monitrage.Exchange
  @domain "https://api.binance.com"

  # valid symbol = BNBETH

  @doc """
  Hello world.
  """
  @impl Monitrage.Exchange
  def fetch_available_coins do
    case HTTPoison.get(@domain <> "/api/v1/exchangeInfo") do
      {:ok, %{body: body, status_code: 200}} ->
        case Jason.decode(body) do
          {:ok, %{"symbols" => symbols}} ->
            {:ok,
             Enum.map(symbols, fn x ->
               "#{String.downcase(x["baseAsset"])}_#{String.downcase(x["quoteAsset"])}"
             end)}

          _err ->
            {:error, "Cannot decode json. The api return format might be changed or other cause."}
        end

      _err ->
        {:error, "Cannot connect to the endpoint."}
    end
  end

  def get_link_symbol(monitrage_symbol) do
    [asset, base] = monitrage_symbol |> String.split("_")

    "https://www.binance.com/en/trade/" <> String.upcase(asset) <> "_" <> String.upcase(base)
  end

  def list_available_coins do
    case fetch_available_coins() do
      {:ok, result} -> result
      _ -> []
    end
  end

  def depth(symbol) do
    case HTTPoison.get(@domain <> "/api/v1/depth?symbol=" <> symbol) do
      {:ok, %{body: body, status_code: 200}} ->
        Jason.decode(body)

      {:ok, %{body: body, status_code: 400}} ->
        case Jason.decode(body) do
          {:ok, %{"msg" => msg}} -> {:error, msg}
          _else -> {:error, "Bad request"}
        end

      {:ok, %{body: body, status_code: other_code}} -> {:error, "Got #{other_code} error."}

      err -> {:error, "unexpected error"}
    end
  end

  def best_offer(monitrage_symbol) do
    case depth(monitrage_symbol |> decode_symbol) do
      {:ok, %{"asks" => asks, "bids" => bids}} ->
        if bids != nil or asks != nil do
            higest_bid = List.first(bids)
            lowest_ask = List.first(asks)
            %{higest_bid: higest_bid, lowest_ask: lowest_ask}
        else
          %{higest_bid: 0, lowest_ask: nil}
        end

      _err -> %{higest_bid: 0, lowest_ask: nil}
    end
  end

  @doc """
  Turn Monitrage standard symbol into Binance standard symbol from bnb_eth to BNBETH
  """
  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    String.upcase(base) <> String.upcase(quoted)
  end
end
