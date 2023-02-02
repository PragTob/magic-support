defmodule MagicTest do
  use ExUnit.Case
  doctest Magic

  test "greets the world" do
    assert Magic.hello() == :world
  end
end
