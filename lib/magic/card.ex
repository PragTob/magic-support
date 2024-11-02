defmodule Magic.Card do
  defstruct [
    :name,
    :set_code,
    :set_name,
    :collector_number,
    :scryfall_id,
    # oracle id is the identity of a card as in, it's the same card
    :oracle_id,
    :prices,
    # yes this conflicts a bit but right now I don't care too much
    foil: false,
    count: 0
  ]

  def from(scryfall_json) do
    prices = Map.fetch!(scryfall_json, "prices")

    %__MODULE__{
      name: Map.fetch!(scryfall_json, "name"),
      oracle_id: oracle_id(scryfall_json),
      set_code: Map.fetch!(scryfall_json, "set"),
      set_name: Map.fetch!(scryfall_json, "set_name"),
      collector_number: Map.fetch!(scryfall_json, "collector_number"),
      scryfall_id: Map.fetch!(scryfall_json, "id"),
      prices: Map.new(prices, fn {key, price} -> {key, price(price)} end)
    }
  end

  defp oracle_id(scryfall_json) do
    # not sure about the fallback, but this code is based on the experience from:
    # https://api.scryfall.com/cards/d74a72a2-d46a-41c2-a400-70571197b020
    Map.get_lazy(scryfall_json, "oracle_id", fn ->
      [oracle_id] =
        scryfall_json
        |> Map.fetch!("card_faces")
        |> Enum.map(& &1["oracle_id"])
        |> Enum.uniq()

      oracle_id
    end)
  end

  defp price(price) do
    case price do
      nil -> nil
      money -> Decimal.new(money)
    end
  end

  def normalize_to_identity(card) do
    %__MODULE__{
      name: card.name,
      set_code: card.set_code
    }
  end
end

defmodule Magic.CardData do
  defstruct [:card, :cheapest_alternatives]

  def create_for(%Magic.Card{} = card) do
    other_printings = Magic.other_printings(card)

    %__MODULE__{
      card: card,
      cheapest_alternatives: build_cheapest_alternatives(other_printings)
    }
  end

  @interested_prices ["eur", "eur_foil", "usd", "usd_foil"]

  @no_alternatives Map.new(@interested_prices, fn key -> {key, nil} end)

  defp build_cheapest_alternatives([]) do
    @no_alternatives
  end

  defp build_cheapest_alternatives(alternatives) do
    Map.new(@interested_prices, fn price_key ->
      {price_key, cheapest_alternative(alternatives, price_key)}
    end)
  end

  defp cheapest_alternative(alternatives, price_key) do
    alternatives
    |> Enum.reject(&is_nil(&1.prices[price_key]))
    |> safe_min_by(& &1.prices[price_key], Decimal)
    |> Magic.CardData.Alternative.from()
  end

  defp safe_min_by(collection, function, comparator)
  defp safe_min_by([], _function, _comparator), do: nil

  defp safe_min_by(collection, function, comparator),
    do: Enum.min_by(collection, function, comparator)

  defmodule Alternative do
    # prices like the scryfall price data
    @keys [:scryfall_id, :set_code, :collector_number, :prices]
    defstruct @keys

    def from(%Magic.Card{} = card) do
      overlap = Map.take(card, @keys)
      struct!(__MODULE__, overlap)
    end

    def from(nil), do: nil
  end
end
