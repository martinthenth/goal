defmodule Goal.StringTest do
  use ExUnit.Case

  describe "squish/1" do
    test "trims consecutive space characters" do
      assert Goal.String.squish("hello  world") == "hello world"
      assert Goal.String.squish("hello    world") == "hello world"
    end

    test "trims leading space characters" do
      assert Goal.String.squish("  hello world") == "hello world"
    end

    test "trims trailing space characters" do
      assert Goal.String.squish("hello world   ") == "hello world"
    end

    test "trims spaces in an empty string" do
      assert Goal.String.squish("   ") == ""
    end
  end
end
