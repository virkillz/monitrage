defmodule Monitrage.Indodax do
  @moduledoc """
  Documentation for Monitrage.
  """

  @domain "https://indodax.com"

  # https://indodax.com/api/ten_btc/depth

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

    "https://indodax.com/market/" <> String.upcase(asset) <> String.upcase(base)

  end

  def list_available_coins do
    case fetch_available_coins() do
      {:ok, result} -> result
      _ -> []
    end
  end

  def decode_symbol(monitrage_symbol) do
    monitrage_symbol
  end

  def depth(symbol) do
    case HTTPoison.get(@domain <> "/api/#{symbol}/depth") do
      {:ok, %{body: body, status_code: 200}} -> Jason.decode(body)
      err -> err
    end
  end

  def best_offer(symbol) do
    case depth(symbol |> decode_symbol) do
      {:ok, %{"sell" => asks, "buy" => bids}} ->
        higest_bid = List.first(bids)
        lowest_ask = List.first(asks)
        %{higest_bid: higest_bid, lowest_ask: lowest_ask}

      err ->
        err
    end
  end
end
