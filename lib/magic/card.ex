defmodule Magic.Card do
  defstruct [
    :name,
    :set,
    :set_name,
    :collector_number
  ]

  def from(scryfall_json) do
    %__MODULE__{
      name: Map.fetch!(scryfall_json, "name"),
      set: Map.fetch!(scryfall_json, "set"),
      set_name: Map.fetch!(scryfall_json, "set_name"),
      collector_number: Map.fetch!(scryfall_json, "collector_number")
    }
  end
end
