defmodule Scryfall.Client do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.scryfall.com")
  plug(Tesla.Middleware.JSON)

  def sets do
    get!("/sets").body["data"]
  end

  def cards_from_set(set_code) do
    get!("/cards/search",
      query: [
        include_extras: true,
        include_variations: true,
        order: :set,
        q: "e:#{set_code}",
        unique: :prints
      ]
    ).body["data"]
  end
end
