defmodule Magic.Card do
  defstruct [
    :name,
    :set_code,
    :set_name,
    :collector_number,
    :scryfall_id,
    foil: false,
    count: 0
  ]

  def from(scryfall_json) do
    %__MODULE__{
      name: Map.fetch!(scryfall_json, "name"),
      set_code: Map.fetch!(scryfall_json, "set"),
      set_name: Map.fetch!(scryfall_json, "set_name"),
      collector_number: Map.fetch!(scryfall_json, "collector_number")
    }
  end
end
