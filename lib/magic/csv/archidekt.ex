defmodule Magic.CSV.Archidekt do
  @doc """
  Turns the given cards into an Archidekt compatible CSV-format.

  cards - list of cards as returned from the Scryfall API.
  """
  alias NimbleCSV.RFC4180, as: CSV

  @headers ["Quantity", "Name", "Collector Number", "Set Code", "Set Name"]

  def to_csv(nil) do
    {:error, "nil cards"}
  end

  def to_csv(cards) do
    rows =
      cards
      |> Enum.map(&Magic.Card.from/1)
      |> Enum.map(&to_row/1)

    data = [@headers | rows]

    csv =
      data
      |> CSV.dump_to_iodata()
      |> IO.iodata_to_binary()

    {:ok, csv}
  end

  defp to_row(card) do
    [0, card.name, card.collector_number, card.set, card.set_name]
  end
end
