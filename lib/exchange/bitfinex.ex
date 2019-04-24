defmodule Monitrage.Bitfinex do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://api.bitfinex.com"

  # btcusd symbol

  def fetch_available_coins do
    case HTTPoison.get(@domain <> "/v1/symbols") do
      {:ok, %{body: body, status_code: 200}} ->
        case Jason.decode(body) do
          {:ok, symbols} ->
            result =
              symbols
              |> Enum.map(fn x -> encode_symbol(x) end)
              |> Enum.filter(fn x -> x != :error end)

            {:ok, result}

          _err ->
            {:error, "Cannot decode json. The api return format might be changed."}
        end

      err ->
        err
    end
  end

  def get_link_symbol(monitrage_symbol) do
    [asset, base] = monitrage_symbol |> String.split("_")

    "https://www.bitfinex.com/t/" <> String.upcase(asset) <> ":" <> String.upcase(base)
  end

  def list_available_coins do
    case fetch_available_coins() do
      {:ok, result} -> result
      _ -> []
    end
  end

  def encode_symbol(symbol) do
    cond do
      String.ends_with?(symbol, "btc") -> String.trim_trailing(symbol, "btc") <> "_" <> "btc"
      String.ends_with?(symbol, "eth") -> String.trim_trailing(symbol, "eth") <> "_" <> "eth"
      String.ends_with?(symbol, "usd") -> String.trim_trailing(symbol, "usd") <> "_" <> "usd"
      true -> :error
    end
  end

  def decode_symbol(monitrage_symbol) do
    [base, quoted] = String.split(monitrage_symbol, "_")
    base <> quoted
  end

  def depth(symbol) do
    case HTTPoison.get(@domain <> "/v1/book/#{symbol}") do
      {:ok, %{body: body, status_code: 200}} -> Jason.decode(body)
      err -> {:error, "Cannot get depth"}
    end
  end

  def best_offer(symbol) do
    case depth(symbol |> decode_symbol) do
      {:ok, %{"asks" => asks, "bids" => bids}} ->
      if bids != nil or asks != nil do
        higest_bid = List.first(bids)
        lowest_ask = List.first(asks)

        %{
          higest_bid: [higest_bid["price"], higest_bid["amount"]],
          lowest_ask: [lowest_ask["price"], lowest_ask["amount"]]
        }
      else
        %{higest_bid: 0, lowest_ask: nil}
      end        


      _err -> %{higest_bid: 0, lowest_ask: nil}
    end
  end
end
