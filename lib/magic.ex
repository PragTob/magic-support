defmodule Magic do
  @doc """
  Fetch all the cards from all the sets and write them into $set-name.csv files.
  """
  def csv_dump do
    # Yes we could parallelize or what not - but the API asks us to be nice and do max 10 req/ s, so - this is us being nice,
    # until we need to be better about being nice.
    sets = Scryfall.Client.sets()
    set_names = Enum.map(sets, fn set -> Map.fetch!(set, "code") end)
    Enum.each(set_names, &csv_dump/1)
  end

  @doc """
  Fetch all the cards of the given set from Scryfall and write them to a CSV file.

  File has the format: Quantity, Name, Collector Number, Set Code, Set Name
  File will be written to csvs/$set_code.csv
  """
  def csv_dump(set_code) do
    path = "csvs/#{set_code}.csv"
    IO.puts("Dumping cards of #{set_code} to #{path}")
    cards = Scryfall.Client.cards_from_set(set_code)

    case Magic.CSV.Archidekt.to_csv(cards) do
      {:ok, csv_contents} ->
        File.write!(path, csv_contents)

      {:error, error} ->
        IO.puts("encountered error: #{error}, while csv creating for #{set_code}")
    end
  end
end
