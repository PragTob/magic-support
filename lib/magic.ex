defmodule Magic do
  def csv_dump do
    # Yes we could parallelize or what not - but the API asks us to be nice and do max 10 req/ s, so - this is us being nice,
    # until we need to be better about being nice.
    sets = Scryfall.Client.sets()
    set_names = Enum.map(sets, fn set -> Map.fetch!(set, "code") end)
    Enum.each(set_names, &csv_dump/1)
  end

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
