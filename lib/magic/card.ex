defmodule Magic.Card do
  defstruct [
    :name,
    :set_code,
    :set_name,
    :collector_number,
    :scryfall_id,
    :price_eur,
    foil: false,
    count: 0
  ]

  def from(scryfall_json) do
    %__MODULE__{
      name: Map.fetch!(scryfall_json, "name"),
      set_code: Map.fetch!(scryfall_json, "set"),
      set_name: Map.fetch!(scryfall_json, "set_name"),
      collector_number: Map.fetch!(scryfall_json, "collector_number"),
      scryfall_id: Map.fetch!(scryfall_json, "id"),
      price_eur: get_in(scryfall_json, ["prices", "eur"])
    }
  end

  def normalize_to_identity(card) do
    %__MODULE__{
      name: card.name,
      set_code: card.set_code,
      collector_number: card.collector_number,
      scryfall_id: card.scryfall_id
    }
  end
end
