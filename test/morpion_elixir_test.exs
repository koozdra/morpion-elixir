defmodule MorpionElixirTest do
  use ExUnit.Case
  doctest MorpionElixir

  test "greets the world" do
    assert MorpionElixir.hello() == :world
  end
end
