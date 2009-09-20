#!/usr/bin/ruby

require 'test/unit'
require 'player.rb'

#All tests in this TestCase are using the player nbTest.  This is because that player has a few dummy games setup
#on alt.org specifically for testing (http://alt.org/nethack/dumplogs.php?player=nbTest).  If you change the playername, 
#the tests will fail unless you change the playername to look at an actual alt.org player.

class PlayerTest < Test::Unit::TestCase
  @@playerName = 'nbTest'
  
  def teardown
    testPlayer = Player.new(@@playerName)
    File.unlink(testPlayer.gamesFile) if File.exists?(testPlayer.gamesFile)
  end
  
  def test_url
    testPlayer = Player.new(@@playerName)
    assert_equal('http://alt.org/nethack/dumplogs.php?player=nbTest', testPlayer.url)
  end

  def test_games_file
    testPlayer = Player.new(@@playerName)
    assert_equal('/Users/markcurtiss/nethack_bot/nbTest.games', testPlayer.gamesFile)
  end

  def test_new_games
    testPlayer = Player.new(@@playerName)
    assert_equal([
        'http://alt.org/nethack/userdata/nbTest/dumplog/1252731025.nh343.txt',
        'http://alt.org/nethack/userdata/nbTest/dumplog/1252731049.nh343.txt'
    ], testPlayer.newGames);
  end

  def test_serialize_game
    testPlayer = Player.new(@@playerName)

    game = testPlayer.newGames[1]
    testPlayer.serializeGame(game)

    assert_equal(
      "http://alt.org/nethack/userdata/nbTest/dumplog/1252731049.nh343.txt\n",
      File.open(testPlayer.gamesFile).gets 
    )
  end

  def test_new_game_excludes_games_which_were_already_serialized
    testPlayer = Player.new(@@playerName)

    games = testPlayer.newGames
    assert_equal(2, testPlayer.newGames.size)
    
    testPlayer.serializeGame(games[1])
    assert_equal(1, testPlayer.newGames.size)

    testPlayer.serializeGame(games[0])
    assert_equal(0, testPlayer.newGames.size)
  end
end