defmodule MonitrageTest do
  use ExUnit.Case
  doctest Monitrage

  test "get list_supported_pairs/1 gives us list all available pairs based on certain exchange" do
    assert {:ok, [_h | _t]} = Monitrage.list_supported_pairs(:tokenomy)
  end

  test "get list_supported_pairs/1 negative test gives error" do
    assert {:error, "Exchange is not supported"} =
             Monitrage.list_supported_pairs(:virkillexchange)
  end

  test "get list_supported_market/0 gives us list all available pairs grouped by its exchange" do
    assert %{} = Monitrage.list_supported_market()
  end
end
