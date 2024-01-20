defmodule Magic.CSV.ArchidektExport do
  @doc """
  Import the Archidekt collection with default Archidekt headers and make them cards.
  """

  alias Magic.Card
  alias NimbleCSV.RFC4180, as: CSV

  def to_cards(collection_path) do
    collection_path
    |> File.stream!()
    |> CSV.parse_stream()
    |> Stream.map(fn [
                       count,
                       name,
                       foil,
                       _condition,
                       _data,
                       _lang,
                       _tags,
                       set_name,
                       set_code,
                       _multi_id,
                       scryfall_id,
                       collector_number
                     ] ->
      # binary copy?
      %Card{
        count: String.to_integer(count),
        name: name,
        foil: foil,
        set_name: set_name,
        set_code: set_code,
        collector_number: collector_number,
        scryfall_id: scryfall_id
      }
    end)
    |> Enum.to_list()
  end
end
