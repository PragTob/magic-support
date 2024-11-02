defmodule Magic do
  alias Magic.Card
  alias Magic.CSV

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
    folder = "csvs"
    File.mkdir_p!(folder)
    path = "#{folder}/#{set_code}.csv"
    IO.puts("Dumping cards of #{set_code} to #{path}")

    cards =
      set_code
      |> Scryfall.Client.cards_from_set()
      |> Enum.map(&Magic.Card.from/1)

    write_archidekt_csv(cards, path)
  end

  # https://mtgjson.com/api/v5/AllDeckFiles.tar.gz
  # functionality isn't really developed since I found the precons on archidekt
  @precon_path "csvs/precons"
  def csv_dump_precons(precons_json_folder_path \\ "jsons/precons") do
    sets_map = build_sets_map()
    files = File.ls!(precons_json_folder_path)

    Enum.each(files, fn file_name ->
      file_path = "#{precons_json_folder_path}/#{file_name}"
      IO.puts("processing #{file_path}")
      file_content = File.read!(file_path)

      %{"commander" => commander, "mainBoard" => main_deck} =
        file_content |> Jason.decode!() |> Map.fetch!("data")

      deck = commander ++ main_deck

      cards =
        Enum.map(deck, fn card ->
          # look up set code to get set name, they should all be the same set though... right?
          # or... we can just create and dump a file
          set_code = Map.fetch!(card, "setCode")

          %Magic.Card{
            name: Map.fetch!(card, "name"),
            collector_number: Map.fetch!(card, "number"),
            set_code: set_code,
            set_name: Map.fetch!(sets_map, String.downcase(set_code)),
            count: Map.fetch!(card, "count"),
            foil: Map.fetch!(card, "isFoil")
          }
        end)

      path = "#{@precon_path}/#{Path.basename(file_name)}.csv"

      write_archidekt_csv(cards, path)
    end)
  end

  defp write_archidekt_csv(cards, path) do
    case CSV.Archidekt.to_csv(cards) do
      {:ok, csv_contents} ->
        File.write!(path, csv_contents)

      {:error, error} ->
        IO.puts("encountered error: #{error}, while csv creating for #{path}")
    end
  end

  defp build_sets_map do
    sets = Scryfall.Client.sets()

    Map.new(sets, fn set -> {Map.fetch!(set, "code"), Map.fetch!(set, "name")} end)
  end

  @doc """
  Given a dumped CSV file with 0-quantity rows, remove the 0 quantity rows.

  Write result to $path_scrubbed.csv
  """
  def csv_scrub(file_path) do
    new_contents = CSV.Archidekt.scrub_csv(file_path)
    scrubbed_path = String.replace(file_path, ".csv", "_scrubbed.csv")
    File.write!(scrubbed_path, new_contents)
  end

  # What cards are missing in the given collection from the given set
  # One of each, not counting specialities I think
  def missing_from(collection_csv_path, set_code) do
    collection = CSV.ArchidektExport.to_cards(collection_csv_path)
    # requires a previous dump from scryfall to be saved in given path
    all_set_cards =
      set_code
      |> Scryfall.Client.cards_from_set()
      |> Enum.map(&Magic.Card.from/1)
      |> Enum.uniq_by(fn card -> card.name end)

    normalized_set_cards = MapSet.new(all_set_cards, &Card.normalize_to_identity/1)

    our_set_cards =
      collection
      |> Enum.filter(fn card -> card.set_code == set_code end)
      # we care that we have one of each
      |> Enum.uniq_by(fn card -> card.name end)
      |> MapSet.new(&Card.normalize_to_identity/1)

    # MapSet for correct diff, sad we can't easily override uniqueness
    unowned_cards = MapSet.difference(normalized_set_cards, our_set_cards)
    unowned_card_names = unowned_cards |> MapSet.to_list() |> Enum.map(& &1.name)

    all_set_cards
    |> Enum.filter(fn card -> card.name in unowned_card_names end)
    |> print_cardmarket_wants()
  end

  defp print_cardmarket_wants(cards) do
    cards
    |> Enum.sort_by(& &1.name)
    |> Enum.each(fn card ->
      IO.puts("1x #{card.name} (#{card.set_name}) -- #{card.prices["eur"]}")
    end)

    total_price =
      cards
      |> Enum.map(& &1.prices["eur"])
      |> Enum.reduce(Decimal.new(0), fn item, sum ->
        case item do
          nil ->
            IO.puts("skipped an unknon price")
            sum

          item ->
            Decimal.add(sum, item)
        end
      end)

    IO.puts("\n#{total_price}")
  end

  def other_printings(%Magic.Card{} = card) do
    # curiously this returns `nil` not empty list, so let's empty list it
    results =
      Scryfall.Client.get_body("cards/search",
        query: [unique: :prints, q: "oracleid:#{card.oracle_id} -scryfall_id:#{card.scryfall_id}"]
      ) || []

    Enum.map(results, &Magic.Card.from/1)
  end

  # limit to the most recent ones and so not to blow up the API
  def fetch_and_dump_secret_lairs(limit \\ 10) do
    secret_lair_data =
      Scryfall.Scraper.sld_overview_parsed()
      |> Enum.take(limit)
      |> Enum.map(&Magic.SecretLairDrop.from/1)

    dbg(secret_lair_data)
  end
end
