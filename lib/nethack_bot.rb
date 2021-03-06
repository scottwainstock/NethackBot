require 'logger'
require 'fileutils'
require 'twitter'
require 'player'

class NethackBot
  attr_accessor :players, :consumer_key, :consumer_secret, :oauth_token, :oauth_token_secret, :twitterAccount, :logger, :silent

  @@logDir = Dir.pwd + (ENV['TEST_DIR'] || '') + '/logs/'
  @@logName = @@logDir + 'nethack_bot.log'

  def initialize(configFile, options = {})
    @silent = options[:silent] || false

    FileUtils.mkpath(@@logDir)

    File.open(configFile, 'r').each { |line|
      line.chomp!
      attribute, values = line.split('=')
      values = values.split(',') if values =~ /,/
      self.send("#{attribute}=", values) if self.respond_to?("#{attribute}")
    }

    self.players.map! { |playerName| Player.new(playerName) }
    self.logger = Logger.new(@@logName, 'daily')
    self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "

    unless (@silent)
      Twitter.configure do |config|
        config.consumer_key = self.consumer_key
        config.consumer_secret = self.consumer_secret
        config.oauth_token = self.oauth_token
        config.oauth_token_secret = self.oauth_token_secret
      end
      self.twitterAccount = Twitter.new
    end
  end

  def run()
    self.logger.info('starting...')
    self.logger.info("running in #{@silent ? 'silent' : 'normal'} mode")

    self.players.each { |player|
      self.logger.debug("#{player.gamesFile} already exists - comparing it to #{player.name}'s games to find new ones") if File.exist?(player.gamesFile)

      player.newGames.each { |newGame|
        deathMetadata = getDeathMetadata(newGame, player.name)

        if (@silent)
          logger.debug("logging #{player.name}'s game #{newGame}")
          player.serializeGame(newGame)
        else
          logger.debug("posting update for #{player.name}'s game #{newGame}")
          tinyGameLogUrl = getTinyUrl(newGame)
          postedToTwitterSuccessfully = ! self.twitterAccount.update(self.statusUpdate(player, tinyGameLogUrl, deathMetadata)).nil?
          logger.debug("successfully posted to twitter?: #{postedToTwitterSuccessfully}")
          player.serializeGame(newGame) if postedToTwitterSuccessfully
        end
      }
    }

    self.logger.info('done!')
  end

  def statusUpdate(player, url, deathMetadata)
    "#{player.name.upcase} the #{deathMetadata[0]} died. Lvl: #{deathMetadata[1]}. Killer: #{deathMetadata[2]}. #{url}"
  end

  def getDeathMetadata(gameLogUrl, playerName)
     commandString = '/usr/bin/curl --silent ' + gameLogUrl
     rawLog = `#{commandString}`.encode('ASCII', :invalid => :replace)

     deathMetadata = Array.new

     rawLog =~ /#{playerName} the (.*).../
     deathMetadata << $1 ? $1 : 'unknown'

     rawLog =~ /^You were level (.*) with a maximum/
     deathMetadata << $1 ? $1 : 'unknown'

     rawLog =~ /^Killer: (.*)/
     deathMetadata << $1 ? $1 : 'unknown'

     return deathMetadata
  end

  def getTinyUrl(gameLogUrl)
     return open('http://tinyurl.com/api-create.php?url=' + gameLogUrl, "UserAgent" => "Ruby-Wget").read
  end

end
