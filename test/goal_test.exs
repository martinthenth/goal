defmodule GoalTest do
  use ExUnit.Case
  doctest Goal

  test "greets the world" do
    assert Goal.hello() == :world
  end
end
