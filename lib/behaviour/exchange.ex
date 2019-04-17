defmodule Monitrage.Exchange do
  @callback fetch_available_coins :: {:ok, result :: map} | {:error, reason :: integer}
end
