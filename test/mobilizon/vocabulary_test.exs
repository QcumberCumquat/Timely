defmodule Mobilizon.VocabularyTest do
  use ExUnit.Case, async: false

  alias Mobilizon.Vocabulary
  alias JSON.LD
  alias Mobilizon.Service.ActivityPub.Utils

  describe "test" do
    test "test" do
      assert "test/fixtures/mastodon-post-activity.json" |> File.read!() |> Jason.decode!() |> JSON.LD.expand() |> hd |> JSON.LD.compact(Utils.make_json_ld_header())  == "toto"

      # assert "test/fixtures/mastodon-reject-activity.json" |> File.read!() |> Jason.decode!() |> JSON.LD.expand()  == "toto"
    end
  end
end