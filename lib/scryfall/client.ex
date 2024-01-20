defmodule Scryfall.Client do
  @doc """
  https://scryfall.com/docs/api
  """
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.scryfall.com")
  plug(Tesla.Middleware.JSON)

  def sets do
    get!("/sets").body["data"]
  end

  # unfinished, turned out no need
  # enforce 75 cards limit
  def cards(scryfall_ids) do
    ids_body_data = Enum.map(scryfall_ids, fn id -> %{"id" => id} end)
    post!("/cards/collection", %{identifies: ids_body_data}).body["data"]
  end

  def cards_from_set(set_code) do
    response =
      get!("/cards/search",
        query: [
          include_extras: true,
          include_variations: true,
          order: :set,
          q: "e:#{set_code}",
          unique: :prints
        ]
      )

    follow_pagination(response.body["data"], response.body["next_page"]) || []
  end

  defp follow_pagination(data, next_page_url)

  defp follow_pagination(data, nil) do
    data
  end

  defp follow_pagination(data, url) do
    pagination_response = get!(url)
    more_data = pagination_response.body["data"]

    follow_pagination(data ++ more_data, pagination_response.body["next_page"])
  end
end
