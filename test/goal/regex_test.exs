defmodule Goal.RegexTest do
  use ExUnit.Case

  alias Goal.Regex

  describe "uuid/0" do
    @regex Regex.uuid()

    test "with valid string, passes validation" do
      assert String.match?("38fb9ab5-6353-47fe-9ff6-19e5fe0f4f46", @regex) == true
    end

    test "with invalid string, fails validation" do
      assert String.match?("38fb9ab5-6353-47fe-9ff6-19e5fe0f4f46aa", @regex) == false
      assert String.match?("uuid", @regex) == false
      assert String.match?("123", @regex) == false
    end
  end

  describe "password/0" do
    @regex Regex.password()

    test "with valid string, passes validation" do
      assert String.match?("password123", @regex) == true
    end

    test "with invalid string, fails validation" do
      assert String.match?("password", @regex) == false
      assert String.match?("123", @regex) == false
    end
  end

  describe "email/0" do
    @regex Regex.email()

    test "with valid string, passes validation" do
      assert String.match?("jane@doe.com", @regex) == true
      assert String.match?("bill.clinton@example.auction", @regex) == true
      assert String.match?("j.h.doe@subdomain.user.com", @regex) == true
      assert String.match?("linda+marie@doe.com", @regex) == true
      assert String.match?("fringilla%mail@doe.com", @regex) == true
      assert String.match?("j/h/doe@subdomain.user.com", @regex) == true
    end

    test "with invalid string, string misses TLD, fails validation" do
      assert String.match?("jane@doe", @regex) == false
    end

    test "with invalid string, string misses domain, fails validation" do
      assert String.match?("jane@.com", @regex) == false
    end

    test "with invalid string, string contains spaces, fails validation" do
      assert String.match?("jane @doe.com", @regex) == false
    end

    test "with invalid string, string contains special characters, fails validation" do
      assert String.match?("bill@clinton@example.auction", @regex) == false
      assert String.match?("chris@subdomain`.user.com", @regex) == false
      assert String.match?("lea[]@example.com", @regex) == false
    end
  end

  describe "url/0" do
    @regex Regex.url()

    test "with valid string, passes validation" do
      assert String.match?("https://www.example.com", @regex) == true
      assert String.match?("http://example.com", @regex) == true
      assert String.match?("http://subdomain.example.com", @regex) == true
      assert String.match?("http://subdomain.subdomain.example.com", @regex) == true
      assert String.match?("example.com", @regex) == true
    end

    test "with invalid string, string misses TLD, fails validation" do
      assert String.match?("http://example", @regex) == false
      assert String.match?("http://example.", @regex) == false
      assert String.match?("http://example.c", @regex) == false
    end

    test "with invalid string, string misses domain, fails validation" do
      assert String.match?("http://.com", @regex) == false
    end

    test "with invalid string, string contains spaces, fails validation" do
      assert String.match?("http://examp le.com", @regex) == false
    end
  end
end
