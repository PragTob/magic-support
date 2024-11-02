defmodule Scryfall.Scraper do
  @moduledoc """
  Secret Lair Drop Data does not seem to be available on the API.

  So... we scrape https://scryfall.com/sets/sld which magically has them.

  ```html
  <span class="card-grid-header-content">
    Featuring: Peach Momoko
    <span class="card-grid-header-dot">•</span>
    <a href="/search?order=set&amp;q=e%3Asld+cn%E2%89%A51667+cn%E2%89%A41671&amp;unique=prints">5 cards</a>
  </span>
  ```
  """

  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://scryfall.com")

  def sld_overview do
    get!("/sets/sld")
  end

  def sld_overview_parsed do
    body = sld_overview().body
    extract_titles_and_links(body)
  end

  def extract_titles_and_links(html) do
    {:ok, document} = Floki.parse_document(html)

    document
    |> Floki.find(".card-grid-header-content")
    |> Enum.map(fn sld_section ->
      name =
        sld_section
        |> Floki.text(deep: false)
        |> String.trim()

      [link] = Floki.attribute(sld_section, "a", "href")

      {name, link}
    end)
  end
end
