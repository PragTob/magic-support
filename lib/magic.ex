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

  # https://mtgjson.com/api/v5/AllDeckFiles.tar.gz
  def csv_dump_precons(folder_path) do
    files = File.ls!(folder_path)

    Enum.each(files, fn file ->
      file_content = File.read!(file)

      # can get overall set code from here again
      %{"commander" => commander, "mainBoard" => main_deck} =
        file_content |> Jason.decode!() |> Map.fetch!("data")

      deck = commander ++ main_deck

      cards =
        Enum.map(deck, fn card ->
          # look up set code to get set name, they should all be the same set though... right?
          # or... we can just create and dump a file
          %Magic.Card{
            name: Map.fetch!(card, "name"),
            collector_number: Map.fetch!(card, "number"),
            set_code: Map.fetch!(card, "set_code"),
            count: Map.fetch!(card, "count"),
            foil: Map.fetch!(card, "isFoil")
          }
        end)
    end)
  end

  @doc """
  Given a dumped CSV file with 0-quantity rows, remove the 0 quantity rows.

  Write result to $path_scrubbed.csv
  """
  def csv_scrub(file_path) do
    new_contents = Magic.CSV.Archidekt.scrub_csv(file_path)
    scrubbed_path = String.replace(file_path, ".csv", "_scrubbed.csv")
    File.write!(scrubbed_path, new_contents)
  end
end
