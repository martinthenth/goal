defmodule Goal.RegexTest do
  use ExUnit.Case

  alias Goal.Regex

  describe "uuid/0" do
    test "with valid string, passes validation" do
      assert String.match?("38fb9ab5-6353-47fe-9ff6-19e5fe0f4f46", Regex.uuid()) == true
    end

    test "with invalid string, fails validation" do
      assert String.match?("38fb9ab5-6353-47fe-9ff6-19e5fe0f4f46aa", Regex.uuid()) == false
      assert String.match?("uuid", Regex.uuid()) == false
      assert String.match?("123", Regex.uuid()) == false
    end

    test "with user-defined regex" do
      Application.put_env(:goal, :uuid_regex, ~r/^[[:alpha:]]+$/)

      assert String.match?("abc", Regex.uuid()) == true
      assert String.match?("123", Regex.uuid()) == false

      Application.delete_env(:goal, :uuid_regex)
    end
  end

  describe "password/0" do
    test "with valid string, passes validation" do
      assert String.match?("password123", Regex.password()) == true
      assert String.match?("password123!", Regex.password()) == true
      assert String.match?("Password123!", Regex.password()) == true
    end

    test "with invalid string, fails validation" do
      assert String.match?("password", Regex.password()) == false
      assert String.match?("123", Regex.password()) == false
    end

    test "with user-defined regex" do
      Application.put_env(:goal, :password_regex, ~r/^[[:alpha:]]+$/)

      assert String.match?("abc", Regex.password()) == true
      assert String.match?("123", Regex.password()) == false

      Application.delete_env(:goal, :password_regex)
    end
  end

  describe "email/0" do
    test "with valid string, passes validation" do
      assert String.match?("jane@doe.com", Regex.email()) == true
      assert String.match?("bill.clinton@example.auction", Regex.email()) == true
      assert String.match?("j.h.doe@subdomain.user.com", Regex.email()) == true
      assert String.match?("linda+marie@doe.com", Regex.email()) == true
      assert String.match?("fringilla%mail@doe.com", Regex.email()) == true
      assert String.match?("j/h/doe@subdomain.user.com", Regex.email()) == true
    end

    test "with invalid string, string misses TLD, fails validation" do
      assert String.match?("jane@doe", Regex.email()) == false
    end

    test "with invalid string, string misses domain, fails validation" do
      assert String.match?("jane@.com", Regex.email()) == false
    end

    test "with invalid string, string contains spaces, fails validation" do
      assert String.match?("jane @doe.com", Regex.email()) == false
    end

    test "with invalid string, string contains special characters, fails validation" do
      assert String.match?("bill@clinton@example.auction", Regex.email()) == false
      assert String.match?("chris@subdomain`.user.com", Regex.email()) == false
      assert String.match?("lea[]@example.com", Regex.email()) == false
    end

    test "with user-defined regex" do
      Application.put_env(:goal, :email_regex, ~r/^[[:alpha:]]+$/)

      assert String.match?("abc", Regex.email()) == true
      assert String.match?("123", Regex.email()) == false

      Application.delete_env(:goal, :email_regex)
    end
  end

  describe "url/0" do
    test "with valid string, passes validation" do
      assert String.match?("https://www.example.com", Regex.url()) == true
      assert String.match?("http://example.com", Regex.url()) == true
      assert String.match?("http://subdomain.example.com", Regex.url()) == true
      assert String.match?("http://subdomain.subdomain.example.com", Regex.url()) == true
      assert String.match?("example.com", Regex.url()) == true
    end

    test "with invalid string, string misses TLD, fails validation" do
      assert String.match?("http://example", Regex.url()) == false
      assert String.match?("http://example.", Regex.url()) == false
      assert String.match?("http://example.c", Regex.url()) == false
    end

    test "with invalid string, string misses domain, fails validation" do
      assert String.match?("http://.com", Regex.url()) == false
    end

    test "with invalid string, string contains spaces, fails validation" do
      assert String.match?("http://examp le.com", Regex.url()) == false
    end

    test "with user-defined regex" do
      Application.put_env(:goal, :url_regex, ~r/^[[:alpha:]]+$/)

      assert String.match?("abc", Regex.url()) == true
      assert String.match?("123", Regex.url()) == false

      Application.delete_env(:goal, :url_regex)
    end
  end

  describe "custom/1" do
    test "with a custom regex" do
      Application.put_env(:goal, :custom_regex, ~r/^[[:alpha:]]+$/)

      assert String.match?("abc", Regex.custom(:custom)) == true
      assert String.match?("123", Regex.custom(:custom)) == false

      Application.delete_env(:goal, :custom_regex)
    end
  end
end
