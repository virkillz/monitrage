defmodule Monitrage.Tokenomy do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://exchange.tokenomy.com"

  def fetch_available_coins do
    case HTTPoison.get(@domain <> "/api/summaries") do
      {:ok, %{body: body, status_code: 200}} ->
        case Jason.decode(body) do
          {:ok, %{"tickers" => tickers}} -> {:ok, Map.keys(tickers)}
          _err -> {:error, "Cannot decode json. The api return format might be changed."}
        end

      err ->
        err
    end
  end

  def get_link_symbol(monitrage_symbol) do
    [asset, base] = monitrage_symbol |> String.split("_")

    "https://exchange.tokenomy.com/market/" <> String.upcase(asset) <> String.upcase(base)
  end

  def list_available_coins do
    case fetch_available_coins() do
      {:ok, result} -> result
      _ -> []
    end
  end

  def depth(symbol) do
    case HTTPoison.get(@domain <> "/api/#{symbol}/depth") do
      {:ok, %{body: body, status_code: 200}} -> Jason.decode(body)
      err -> {:error, "Cannot get depth"}
    end
  end

  def decode_symbol(monitrage_symbol) do
    monitrage_symbol
  end

  def best_offer(symbol) do
    case depth(symbol |> decode_symbol) do
      {:ok, %{"sell" => asks, "buy" => bids}} ->
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
end
