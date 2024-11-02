defmodule Scryfall.ScraperTest do
  use ExUnit.Case, async: true

  alias Scryfall.Scraper

  test "extracts the name and link fine" do
    html = """
    <span class="card-grid-header-content">
      Featuring: Peach Momoko
      <span class="card-grid-header-dot">•</span>
      <a href="/search?order=set&amp;q=e%3Asld+cn%E2%89%A51667+cn%E2%89%A41671&amp;unique=prints">5 cards</a>
    </span>
    """

    assert [
             {"Featuring: Peach Momoko",
              "/search?order=set&q=e%3Asld+cn%E2%89%A51667+cn%E2%89%A41671&unique=prints"}
           ] = Scraper.extract_titles_and_links(html)
  end

  test "can deal with multiple elements and some noise fine" do
    html = """
    <h2 class="card-grid-header" id="extra-life-2024-pixel-perfect">
      <span class="card-grid-header-inner">
        <span class="card-grid-header-content">
          Extra Life 2024: Pixel Perfect
          <span class="card-grid-header-dot">•</span>
          <a href="/search?order=set&amp;q=e%3Asld+%28%28cn%E2%89%A51821+cn%E2%89%A41824%29+OR+cn%3A%22886%22%29&amp;unique=prints">5 cards</a>
        </span>
      </span>
    </h2>
    <div class="card-grid">
      <div class="card-grid-inner">
      </div>
    </div>
    <h2 class="card-grid-header" id="featuring-peach-momoko">
      <span class="card-grid-header-inner">
        <span class="card-grid-header-content">
          Featuring: Peach Momoko
          <span class="card-grid-header-dot">•</span>
          <a href="/search?order=set&amp;q=e%3Asld+cn%E2%89%A51667+cn%E2%89%A41671&amp;unique=prints">5 cards</a>
        </span>
      </span>
    </h2>
    """

    assert [
             {"Extra Life 2024: Pixel Perfect",
              "/search?order=set&q=e%3Asld+%28%28cn%E2%89%A51821+cn%E2%89%A41824%29+OR+cn%3A%22886%22%29&unique=prints"},
             {"Featuring: Peach Momoko",
              "/search?order=set&q=e%3Asld+cn%E2%89%A51667+cn%E2%89%A41671&unique=prints"}
           ] = Scraper.extract_titles_and_links(html)
  end
end
