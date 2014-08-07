#!/usr/bin/env ruby

require 'optparse'
require 'ostruct' 
require 'tweetstream'
require 'timeout'
require 'pp' 
require 'active_record'
require 'mysql2'
require 'yaml' 

config = YAML::load(File.open('database.yml'))
ActiveRecord::Base.establish_connection(config["development"])

class Tweet < ActiveRecord::Base
end

class RKeywords
  def run
    options = {:num_tweets => 10}
    OptionParser.new do |opts|
      opts.banner = "Usage: rtweet.rb [-n Number of Tweets] keywords_file"

      opts.on("-n", '--numtweets N', "Number of tweets to grab") do |n|
        options[:num_tweets] = n
      end
    end.parse!

    p options
    p ARGV

    keywords = get_keywords(ARGV[0])
    start_tweet_stream(keywords)
  end

  def get_keywords(keyword_file)
    File.readlines(keyword_file).each {|l| l.chomp!}
  end

  def start_tweet_stream(keywords)
    TweetStream.configure do |config|
      config.consumer_key       = ENV["CONSUMER_KEY"]       
      config.consumer_secret    = ENV["CONSUMER_SECRET"]    
      config.oauth_token        = ENV["ACCESS_TOKEN"]       
      config.oauth_token_secret = ENV["ACCESS_TOKEN_SECRET"]
      config.auth_method        = :oauth
    end

    #begin
      #complete_results = Timeout.timeout(120) do

    i = 0
    TweetStream::Client.new.on_delete{ |status_id, user_id|
      puts "Deleting Tweet: #{status_id}"
      Tweet.delete(status_id)
    }.on_limit { |skip_count|
      puts "Rate Limited: #{skip_count}"
    }.track(keywords) do |status|
      i += 1
      Tweet.create(text: "#{status.text}")
      client.stop if i >= 2
    end

    #end
    #rescue Timeout::Error
    #  puts 'Getting Tweets timed out.'
    #end
  end
end

# Create and run the application
app = RKeywords.new
app.run
