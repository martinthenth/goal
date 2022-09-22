defmodule Goal.Regex do
  @moduledoc """
  Defines regexes.
  """

  @doc false
  @spec uuid :: Regex.t()
  def uuid do
    ~r/^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$/
  end

  @doc false
  @spec email :: Regex.t()
  def email do
    ~r/^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
  end

  @doc false
  @spec password :: Regex.t()
  def password do
    ~r/^(?=.*[0-9])(?=.*[a-zA-Z])([a-zA-Z0-9]+)$/
  end

  @doc false
  @spec url :: Regex.t()
  def url do
    ~r/^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/
  end
end
