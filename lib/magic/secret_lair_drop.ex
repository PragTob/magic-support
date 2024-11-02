defmodule Magic.SecretLairDrop do
  defstruct [:name, :card_data, :scryfall_search, :total_price, :cheapest_total_others]

  def from({name, scryfall_search}) do
    cards =
      "/cards#{scryfall_search}"
      |> Scryfall.Client.get_body()
      |> Enum.map(&Magic.Card.from/1)

    card_data = Enum.map(cards, &Magic.CardData.create_for/1)

    %__MODULE__{
      name: name,
      scryfall_search: scryfall_search,
      # card_data: card_data,
      total_price: total_prices(cards),
      cheapest_total_others: cheapest_total_price(card_data)
    }
  end

  @interested_prices ["eur", "eur_foil", "usd", "usd_foil"]
  defp total_prices(cards) do
    IO.puts("JUST TOTAL")

    Map.new(@interested_prices, fn price_key ->
      {price_key, price_sum(cards, [Access.key!(:prices), price_key])}
    end)
  end

  defp cheapest_total_price(card_data) do
    IO.puts("CHEAPEST TOTAL")

    Map.new(@interested_prices, fn price_key ->
      {price_key,
       price_sum(card_data, [
         Access.key!(:cheapest_alternatives),
         price_key,
         Access.key!(:prices),
         price_key
       ])}
    end)
  end

  def price_sum([], _no), do: nil

  def price_sum(cards, access_keys) do
    prices =
      cards
      |> dbg()
      |> Enum.map(&get_in(&1, access_keys))
      |> Enum.reject(&is_nil/1)

    total_price = Enum.reduce(prices, Decimal.new(0), &Decimal.add/2)
    missing = length(cards) - length(prices)

    if(missing == 0) do
      total_price
    else
      {total_price, missing: missing}
    end
  end
end
