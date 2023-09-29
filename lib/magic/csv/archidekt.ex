defmodule Magic.CSV.Archidekt do
  @doc """
  Turns the given cards into an Archidekt compatible CSV-format.

  cards - list of cards as returned from the Scryfall API.
  """
  alias NimbleCSV.RFC4180, as: CSV

  @headers ["Quantity", "Name", "Collector Number", "Set Code", "Set Name", "Foil"]

  def to_csv(nil) do
    {:error, "nil cards"}
  end

  def to_csv(cards) do
    rows = Enum.map(cards, &to_row/1)

    data = [@headers | rows]

    {:ok, to_csv_binary(data)}
  end

  defp to_csv_binary(data) do
    data
    |> CSV.dump_to_iodata()
    |> IO.iodata_to_binary()
  end

  defp to_row(card) do
    [card.count, card.name, card.collector_number, card.set_code, card.set_name, card.foil]
  end

  @doc """
  Remove all 0 quantity rows from given CSV

  Archidekt import doesn't like 0 quantity and defaults them to 1...
  So, do this dance where we remove the rows.
  """
  def scrub_csv(file_path) do
    file_path
    |> File.stream!()
    |> CSV.parse_stream(skip_headers: false)
    |> Stream.reject(fn [quantity | _] -> quantity == "0" end)
    |> to_csv_binary()
  end
end
